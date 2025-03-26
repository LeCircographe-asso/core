console.log("Le fichier home_animations.js est chargé!");

document.addEventListener('turbo:load', initAnimations);
document.addEventListener('DOMContentLoaded', initAnimations);

function initAnimations() {
    // Éléments à animer
    const titleElement = document.getElementById('title');
    const mainButton = document.querySelector('.main-button');
    const mainContent = document.getElementById('main-content');
    const scrollArrow = document.querySelector('.scroll-arrow-container');
    
    // Vérifier si les éléments existent
    if (!titleElement || !mainButton || !mainContent) {
        console.error("Certains éléments de la page n'ont pas été trouvés");
        return; // Sortir si des éléments sont manquants
    }
    
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    
    if (prefersReducedMotion) {
        // Afficher immédiatement tout le contenu sans animation
        titleElement.classList.remove('opacity-0');
        mainButton.classList.remove('opacity-0');
        mainContent.classList.remove('opacity-0');
        if (scrollArrow) scrollArrow.classList.remove('opacity-0');
    } else {
        // Animation lettre par lettre pour le titre
        animateTextLetterByLetter(titleElement);
        
        // Animation des autres éléments après le titre
        setTimeout(() => mainButton.classList.remove('opacity-0'), 1500);
        if (scrollArrow) setTimeout(() => scrollArrow.classList.remove('opacity-0'), 1800);
        setTimeout(() => mainContent.classList.remove('opacity-0'), 2000);
    }
    
    // Fallback de sécurité - rendre tout visible si JavaScript échoue partiellement
    window.setTimeout(function() {
        document.querySelectorAll('.opacity-0').forEach(el => el.classList.remove('opacity-0'));
    }, 4000);
    
    // Initialiser le défilement fluide pour les ancres
    initSmoothScroll();
}

function animateTextLetterByLetter(element) {
    // Récupérer le texte original
    const text = element.textContent;
    
    // Vider le contenu original
    element.innerHTML = '';
    
    // Afficher l'élément (retirer opacity-0)
    element.classList.remove('opacity-0');
    
    // Créer un span pour chaque lettre et l'ajouter directement au titre
    let delay = 100; // Délai initial
    
    for (let i = 0; i < text.length; i++) {
        const letterSpan = document.createElement('span');
        
        // Si c'est un espace, utiliser un espace insécable pour préserver la largeur
        if (text[i] === ' ') {
            letterSpan.innerHTML = '&nbsp;';
            letterSpan.style.marginRight = '0.25em'; // Assurer un espace visible
        } else {
            letterSpan.textContent = text[i];
        }
        
        letterSpan.style.opacity = '0';
        letterSpan.style.transition = 'opacity 150ms ease';
        element.appendChild(letterSpan);
        
        // Programmer l'apparition de chaque lettre
        setTimeout(() => {
            letterSpan.style.opacity = '1';
        }, delay);
        
        delay += 100; // Ajouter un délai pour chaque lettre
    }
}

// Fonction pour initialiser le défilement fluide
function initSmoothScroll() {
    // Sélectionner tous les liens qui commencent par #
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            
            const targetId = this.getAttribute('href');
            const targetElement = document.querySelector(targetId);
            
            if (targetElement) {
                // Calcul de la position avec un décalage (offset) si nécessaire
                const offset = 50; // Ajustez selon vos besoins
                const targetPosition = targetElement.getBoundingClientRect().top + window.pageYOffset - offset;
                
                // Animation de défilement fluide
                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
            }
        });
    });
}