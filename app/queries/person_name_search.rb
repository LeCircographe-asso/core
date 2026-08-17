# frozen_string_literal: true

# Recherche de personne par nom, utilisée par les pickers admin (prêt de carnet,
# bénéficiaires additionnels d'une cotisation). Les critères métier additionnels
# (ex. carnet actif) restent dans l'appelant ; ce module ne fait que la recherche
# par nom + l'exclusion d'ids.
module PersonNameSearch
  MIN_QUERY_LENGTH = 2

  def self.call(query:, exclude_ids: [], limit: 10)
    normalized = query.to_s.strip
    return Person.none if normalized.length < MIN_QUERY_LENGTH

    like = "%#{normalized}%"
    Person.where.not(id: Array(exclude_ids))
          .where("first_name LIKE :q OR last_name LIKE :q", q: like)
          .limit(limit)
  end
end
