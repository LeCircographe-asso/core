# Plan — Index sémantique local + MCP interrogeable par Claude

> **Statut** : internal
> **Public cible** : équipe dev
> **Dernière vérification** : 2026-08-27
> **Sources de vérité** :
> - `bin/rspec`, `bin/test`, `bin/test_fast` (commandes et verrou SQLite)
> - `docs/README.md` (gouvernance documentaire)
> - `docs/glossary.md` (vocabulaire canonique)
> - `app/services/base_service.rb` (pattern `success`/`failure`)
>
> **Raison de présence dans `internal/`** : plan d'outillage en cours, non exécuté,
> sans impact sur le code applicatif. Migrera vers `legacy/` une fois réalisé.
>
> **À vérifier** :
> - [ ] Syntaxe `.mcp.json` toujours valide (`claude mcp add`) au moment de l'implémentation
> - [ ] Modèles Ollama : vérifier `ollama.com/library` (le paysage bouge vite)

---

## Préambule d'exécution

Document **autonome** : il ne suppose aucun contexte de la conversation où il a été rédigé.
À ouvrir dans une session Claude Code neuve, depuis WSL2 (terminal RubyMine), à la racine du repo.

**Cible matérielle** : poste dev solo, RTX 3080, WSL2, Rails 8.1 / Ruby 4.0.1.

**Aucun fichier applicatif n'est modifié par ce plan.** Tout est additif :
`scripts/ai/`, `.mcp.json`, `CLAUDE.md`, `.claude/settings.json`.

---

## 1. L'objectif

Faire tourner un modèle local sur la 3080 **et rendre Claude capable de l'interroger
correctement**. Le second point est le vrai sujet : un Ollama installé que Claude n'appelle
jamais, ou appelle mal, ne sert à rien.

**Le problème concret.** À la question « où est gérée la fusion de deux `Person` ? », Claude
fait aujourd'hui du grep à l'aveugle sur ~197 fichiers `app/` + ~172 specs, lit 8 fichiers
pour n'en garder qu'un, et tout cela s'accumule dans le contexte. C'est le poste de dépense
n°1 en tokens sur ce repo.

**La cible.** Claude appelle un outil local, reçoit
`app/services/people/account_merger.rb:34` + 3 lignes de contexte en ~200 ms, pour 0 token
d'API. Il lit *un* fichier, le bon.

**Pourquoi un MCP ici, alors qu'on le déconseille ailleurs** (§11) : envelopper dans un
protocole des commandes que Bash lance déjà (RSpec, Rake, RuboCop) n'apporte rien. La
recherche sémantique locale est l'inverse — une capacité que Claude **n'a pas**, et le MCP
est le seul moyen propre de la lui donner de façon *découvrable*, c'est-à-dire sans avoir à
le lui rappeler à chaque session.

---

## 2. Architecture

```
Claude Code (WSL2)
      │  stdio / MCP
      ▼
scripts/ai/mcp_server.py          ← expose 3 outils à Claude
      │
      ├──► SQLite  scripts/ai/index.db     (chunks + vecteurs + métadonnées)
      │
      └──► Ollama  http://localhost:11434
                     ├── nomic-embed-text    (embeddings, ~300 Mo VRAM)
                     └── qwen2.5-coder:7b    (synthèse/triage, ~4,7 Go VRAM)
                                              RTX 3080
```

Budget VRAM des deux modèles résidents : **~5 Go**. Confortable sur une 3080 10 Go,
très confortable sur 12 Go.

**Volumétrie** : ~197 fichiers `app/`, ~172 `spec/`, ~30 `docs/`. Après découpage par
méthode/section : **2 000 à 4 000 chunks**. C'est petit — un produit scalaire en force brute
sur 4 000 vecteurs prend quelques millisecondes. **Pas besoin de base vectorielle.**

---

## 3. Partie A — L'index

### 3.1 Découpage (la partie qui décide de la qualité)

Le découpage à taille fixe (« 500 tokens par chunk ») donne de mauvais résultats sur du
code : il coupe au milieu des méthodes. **Découper par unité sémantique.**

**Ruby** — un chunk = une méthode, préfixée de son en-tête de classe :

```
Fichier : app/services/people/account_merger.rb
Chunk   : "People::AccountMerger < BaseService — def call(source:, target:)"
          + corps de la méthode
Méta    : path, ligne_début, ligne_fin, classe, méthode, kind=service
```

Le préfixage par le nom complet de la classe fait la différence entre une recherche qui
marche et une qui ne marche pas : le corps d'un `def call` isolé est sémantiquement vide,
`People::AccountMerger#call` ne l'est pas.

Parsing via **Prism** (parser Ruby officiel, embarqué depuis 3.3) : bornes exactes des
`class`/`module`/`def`, bien plus fiable qu'une regex. Script `scripts/ai/chunk.rb` émettant
du JSONL, consommé par le Python.

**Markdown (`docs/`)** — un chunk = une section `##`, préfixée du titre du document.
`docs/` est gouverné et à jour : c'est le meilleur matériau de l'index.

**Exclusions** : `db/schema.rb`, migrations, `vendor/`, `tmp/`, `log/`, `storage/`,
`db/*.sqlite3`, `config/credentials.yml.enc`, `.kamal/secrets`.

### 3.2 Embeddings

`nomic-embed-text` — 768 dimensions, fenêtre 8k, rapide sur une 3080.
(`mxbai-embed-large`, 1024 dims, est meilleur pour ~3× le coût — testable, le ré-index
complet ne prend que quelques minutes.)

Un embedding = un `POST /api/embeddings` à Ollama. 4 000 chunks : quelques minutes en batch.

### 3.3 Stockage

```sql
CREATE TABLE chunks (
  id INTEGER PRIMARY KEY,
  path TEXT NOT NULL,
  line_start INTEGER, line_end INTEGER,
  kind TEXT,              -- model | service | controller | component | spec | doc
  symbol TEXT,            -- "People::AccountMerger#call"
  content TEXT NOT NULL,
  content_sha TEXT NOT NULL,     -- indexation incrémentale
  embedding BLOB NOT NULL        -- float32 * 768
);
CREATE INDEX idx_chunks_path ON chunks(path);
CREATE VIRTUAL TABLE chunks_fts USING fts5(symbol, content, content=chunks);
```

FTS5 (natif SQLite) sert la voie lexicale de la recherche hybride.

**Incrémental** : `git diff --name-only <sha> HEAD` → ne ré-embedder que les fichiers
touchés ; `content_sha` évite de ré-embedder un chunk inchangé dans un fichier modifié.
Ré-index d'une branche de travail : quelques secondes.

`scripts/ai/index.db` → `.gitignore` (binaire, régénérable).

### 3.4 Recherche hybride — **ne pas sauter**

C'est l'erreur classique. La recherche purement vectorielle est excellente sur
« où fusionne-t-on deux adhérents ? » et **médiocre** sur « trouve `AccountMerger` » :
les embeddings ne font pas l'appariement exact d'identifiants.

**Combiner les deux, systématiquement :**

1. Vectoriel : cosinus sur les vecteurs → top 20
2. Lexical : FTS5 + `rg` sur le terme littéral → top 20
3. Fusion **RRF** (Reciprocal Rank Fusion) : `score = Σ 1/(60 + rang_i)`
   — simple, sans paramètre à régler, robuste. ~15 lignes de Python.
4. Retourner les 8 meilleurs.

Sans la voie lexicale, l'outil marche une fois sur deux — et Claude apprend à ne plus l'appeler.

---

## 4. Partie B — Le serveur MCP

SDK officiel `mcp` (Python), transport stdio, venv isolé dans `scripts/ai/.venv`.
Aucune interaction avec le `Gemfile`.

### 4.1 Les trois outils

**`search_codebase(query, kind?, top_k?)`** — le cœur. Retourne des **pointeurs**, pas du contenu :

```
app/services/people/account_merger.rb:34-71  [service]  People::AccountMerger#call
  Fusionne source dans target, préserve l'historique financier
  → 3 lignes de contexte

docs/domain/happy_path_flows.md:88-104  [doc]  Flux Link
  → 3 lignes de contexte
```

**Plafonner durement la sortie** : 8 résultats, 3 lignes chacun, ~400 tokens au total.
Un outil de recherche qui renvoie 5 000 tokens de code a détruit sa propre raison d'être.
La valeur est dans le *pointage*, pas dans la restitution.

**`triage_log(path, lines?, question?)`** — synthèse locale de logs.
Lit la fin de `log/development.log`, l'envoie à `qwen2.5-coder:7b`, retourne 5–10 lignes :
type d'erreur, fichier applicatif en cause, occurrences, gravité. 2 000 lignes de trace →
résumé actionnable, **0 token d'API**. Second meilleur usage du modèle local.

**`domain_lookup(term)`** — vocabulaire canonique.
`docs/glossary.md` est normatif et contient des termes interdits. Recherche exacte puis
sémantique → définition + terme canonique + fichiers de référence. Évite qu'un agent invente
un nom de classe qui viole le glossaire.

### 4.2 Rendre l'invocation correcte

Un outil MCP est décrit à Claude par sa `description`. **Cette description est un prompt.**
C'est là que se joue « est-ce que Claude l'appelle, et au bon moment ». Une description molle
(« recherche dans le code ») produit un outil ignoré.

```python
@mcp.tool()
def search_codebase(query: str, kind: str | None = None, top_k: int = 8) -> str:
    """Recherche sémantique locale sur le code et la doc du Circographe.

    UTILISE CET OUTIL EN PREMIER pour toute question du type "où est géré X",
    "quel service fait Y", "où sont les règles de Z" — AVANT tout Grep/Glob et
    AVANT de lancer un sous-agent d'exploration. Gratuit, local, ~200 ms.

    Retourne des pointeurs (chemin:lignes + symbole + extrait court), pas le
    contenu complet : lis ensuite le fichier pertinent avec Read.

    Recherche hybride (vectorielle + lexicale) : marche aussi bien sur une
    intention formulée en français que sur un nom de classe exact.

    kind (optionnel) : model | service | controller | component | spec | doc
      → restreint la recherche. Ex. kind="doc" pour les règles métier,
        kind="service" pour la logique applicative.

    Ne l'utilise PAS pour lire un fichier dont tu connais déjà le chemin (Read),
    ni pour un renommage exhaustif où il faut TOUTES les occurrences (Grep).
    """
```

Les quatre éléments qui font qu'un outil est bien appelé :

1. **Déclencheur explicite** — « UTILISE EN PREMIER pour les questions "où est…" ».
   Sans ça, Claude reste sur ses réflexes Grep.
2. **Contrepartie négative** — « ne l'utilise PAS pour… ». Aussi importante que le positif :
   elle évite les appels absurdes qui feraient perdre confiance dans l'outil.
3. **Contrat de retour** — « retourne des pointeurs, lis ensuite avec Read ». Claude doit
   savoir que la sortie est un index, pas une réponse.
4. **Le coût** — « gratuit, local, 200 ms ». Un modèle qui sait qu'un outil est bon marché
   l'appelle plus volontiers, y compris spéculativement. C'est exactement ce qu'on veut.

**Renfort dans `CLAUDE.md`** (ceinture et bretelles) :

```markdown
## Recherche dans le code
Ce projet expose un index sémantique local via MCP (`search_codebase`).
Pour toute question d'architecture ou de localisation, appelle-le AVANT Grep/Glob.
Il est gratuit et local. Grep reste le bon outil pour les remplacements exhaustifs.
```

**Enregistrement** — `.mcp.json` à la racine (portée projet, versionné) :

```json
{
  "mcpServers": {
    "circographe": {
      "command": "${PWD}/scripts/ai/.venv/bin/python",
      "args": ["${PWD}/scripts/ai/mcp_server.py"]
    }
  }
}
```

Vérifier la syntaxe exacte via `claude mcp add` au moment de l'implémentation — c'est le
point le plus susceptible d'avoir changé. En cas de doute : chemins absolus.

**Coût du MCP lui-même** : les 3 définitions d'outils sont envoyées à chaque requête,
~400–600 tokens. Prix d'entrée amorti dès la première exploration évitée (un sous-agent
coûte 10 000+ tokens). **Rester à 3 outils** — c'est aussi pourquoi il n'y a pas de
`run_tests` ni de `run_rubocop` : Bash les fait déjà, ils ne feraient qu'alourdir.

---

## 5. Partie C — Ollama sur WSL2 + 3080

**Installer Ollama _dans_ WSL2**, pas sur Windows. Un Ollama Windows force à traverser
l'interface réseau WSL→hôte : IP changeante, pare-feu, latence. Dans WSL2 c'est
`localhost:11434` et les chemins correspondent au repo.

Le pilote NVIDIA s'installe **sur Windows uniquement**. Ne jamais installer de pilote NVIDIA
dans WSL2 — c'est l'erreur classique qui casse CUDA.

```bash
nvidia-smi                                   # doit voir la 3080 depuis WSL2
curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen2.5-coder:7b
ollama pull nomic-embed-text
```

`qwen2.5-coder:7b` est une référence solide et connue sur ce créneau, mais le paysage bouge
vite : vérifier `ollama.com/library` à l'installation. Le plan ne dépend pas du modèle,
c'est une ligne de config.

**Service permanent** — WSL2 moderne supporte systemd via `/etc/wsl.conf` :

```ini
[boot]
systemd=true
```

Variables importantes :

```bash
OLLAMA_KEEP_ALIVE=-1        # garde les modèles résidents (sinon déchargement après 5 min)
OLLAMA_MAX_LOADED_MODELS=2  # embed + coder simultanément
```

Sans `KEEP_ALIVE`, chaque recherche après 5 min d'inactivité paie un rechargement de
plusieurs secondes — et un outil lent est un outil que Claude cesse d'appeler.

**Contrôle** : `nvidia-smi` doit montrer les deux modèles en VRAM. S'ils tournent sur CPU
(20× plus lent), c'est le passage CUDA→WSL qui est cassé, pas Ollama.

---

## 6. Prérequis bon marché

**`CLAUDE.md` est un prérequis du MCP** : c'est là qu'on écrit la consigne
« appelle `search_codebase` avant Grep ».

**`CLAUDE.md`** (~100 lignes, 1 h) — **routeur, pas copie de `docs/`**. Dupliquer la doc
créerait de la dérive et ferait payer des milliers de tokens à chaque session. Contenu :

- Commandes réelles : `bin/dev`, `bin/test`, `bin/test_fast`, `bin/rubocop`, `bin/brakeman`
- **Pièges** : `bin/rspec` prend un flock (`tmp/locks/rspec.sqlite.lock`) → jamais deux runs
  de tests concurrents ; vocabulaire canonique obligatoire (`docs/glossary.md`) ; branches
  `dev` → `staging` → `main`, jamais de push sur `main` ; jamais de Kamal depuis un agent
- Carte de navigation vers `docs/` (liens, pas de contenu recopié)
- La consigne `search_codebase` ci-dessus

**`.claude/settings.json`** (20 min) — allowlist : `bin/test*`, `bin/rubocop`,
`git status/diff/log`, `Read(app/**)`, `Read(docs/**)`.
Deny : `credentials.yml.enc`, `master.key`, `.kamal/secrets`, `db/*.sqlite3`, `bin/kamal`,
`db:drop`, `db:reset`.

---

## 7. Fichiers à créer

```
scripts/ai/
├── chunk.rb              # découpage Ruby via Prism → JSONL
├── index.py              # embeddings + écriture SQLite + incrémental git
├── search.py             # cosinus + FTS5 + fusion RRF
├── mcp_server.py         # 3 outils MCP (descriptions soignées)
├── requirements.txt      # mcp, numpy, httpx
├── .venv/                # gitignoré
└── index.db              # gitignoré

.mcp.json                 # déclaration du serveur (racine, versionné)
CLAUDE.md                 # routeur + consigne search_codebase
.claude/settings.json     # permissions
```

`.gitignore` : ajouter `scripts/ai/.venv/`, `scripts/ai/index.db`,
`.claude/settings.local.json`.

`scripts/` n'existe pas encore (les utilitaires sont dans `bin/`) — pas de collision.
Ne pas mettre ça dans `bin/`, territoire des binstubs Rails.

---

## 8. Séquencement

| # | Session | Durée | Livrable vérifiable |
| --- | --- | --- | --- |
| 1 | Ollama WSL2 + 2 modèles + systemd + keep-alive | 1 h | `nvidia-smi` montre les modèles en VRAM |
| 2 | `CLAUDE.md` + allowlist | 1 h 30 | Session neuve qui connaît le flock SQLite |
| 3 | `chunk.rb` + `index.py` → premier index complet | 2 h | `index.db` peuplé, nb de chunks affiché |
| 4 | `search.py` hybride + RRF, testé **en CLI** | 2 h | 10 questions réelles, résultats pertinents |
| 5 | `mcp_server.py` + `.mcp.json` + descriptions | 1 h 30 | `/mcp` liste les 3 outils, Claude les appelle |
| 6 | `triage_log` + index incrémental sur hook git | 1 h 30 | Triage d'un vrai log ; ré-index en secondes |

**La session 4 est la charnière.** Valider la qualité de recherche **en ligne de commande**
avant de brancher le MCP. Si la recherche est médiocre, le MCP ne fera que l'exposer plus
vite. Debugger `search.py` en CLI est trivial ; le debugger à travers le protocole MCP ne
l'est pas.

Jeu de validation (mélange intention / identifiant exact) :

| Question | Attendu |
| --- | --- |
| « où fusionne-t-on deux adhérents ? » | `People::AccountMerger` |
| « règles de calcul des dons » | `docs/payments.md` + service concerné |
| « AccountLinker » | le fichier exact (teste la voie lexicale) |
| « comment on marque une adhésion expirée » | `MembershipDeactivator` ou le job |
| « invariant User Person » | `docs/domain/data_integrity_rules.md` |

Une question qui échoue = problème de découpage ou de préfixage, pas de modèle.

---

## 9. Vérification

**Index** — `index.py --stats` : nombre de chunks, répartition par `kind`, 5 chunks relus à
la main. Un chunk qui commence au milieu d'une méthode = chunker à corriger.

**Recherche** — les 5 questions ci-dessus en CLI. Le bon résultat doit être **dans le top 3**.
Top 8 est insuffisant : Claude n'ira pas au 7ᵉ résultat.

**MCP** — `/mcp` liste `circographe` et ses 3 outils. Redémarrer la session après
modification de `.mcp.json`.

**Invocation correcte** — le test qui compte. Session neuve :
« où est gérée la fusion de deux Person ? »
→ Claude doit appeler `search_codebase` **spontanément, en premier**, sans qu'on le demande,
puis lire un seul fichier. S'il fait du Grep d'abord, la description est trop molle :
durcir le déclencheur et renforcer la ligne dans `CLAUDE.md`.

**Bout en bout** — comparer la même question d'architecture avant/après via `/context`.

---

## 10. Modes d'échec

- **Déception sur les identifiants exacts** — structurel, d'où l'hybride RRF. Sauter la voie
  lexicale donne un outil décevant une fois sur deux.
- **Index périmé** — pointer vers des lignes qui ont bougé fait perdre du temps.
  Ré-index incrémental sur hook `post-commit` ou au démarrage de session.
- **Le 7B ne code pas le Rails** — il ne remplacera pas Claude sur 53 services
  interconnectés. Son périmètre : *embeddings* et *synthèse*. Lui faire écrire un service
  coûte plus en correction que ce qu'il économise.
- **Trop d'outils MCP tue le MCP** — chaque outil coûte des tokens à chaque requête et dilue
  le choix. Trois, c'est bien.
- **Un outil lent n'est plus appelé** — d'où `OLLAMA_KEEP_ALIVE=-1`. Une recherche à
  3 secondes et tout le monde retourne à Grep.

---

## 11. Ce qu'il ne faut pas faire

- ❌ MCP pour Rake / RSpec / SQLite — Bash le fait déjà, n'ajoute que du poids par requête.
- ❌ MCP GitHub — `gh` en CLI sous WSL2 fait le travail pour moins cher.
- ❌ Base vectorielle (Chroma, Qdrant, pgvector) — 4 000 vecteurs, SQLite suffit ;
  un service de plus pour un gain nul.
- ❌ Chunks à taille fixe — coupe les méthodes, dégrade la recherche.
- ❌ Renvoyer le contenu complet des fichiers depuis `search_codebase` — annule le bénéfice.
- ❌ Installer un pilote NVIDIA dans WSL2 — casse CUDA. Le pilote est sur Windows uniquement.
- ❌ Dupliquer `docs/` dans `CLAUDE.md` — dérive garantie, tokens payés à chaque session.
- ❌ Toucher au modèle `BugReport` — fonctionnalité produit vivante, hors sujet ici.
