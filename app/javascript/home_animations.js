document.addEventListener('turbo:load', initAnimations);

function initAnimations() {
    // Éléments à animer
    const titleElement = document.getElementById('title');
    const mainButton = document.querySelector('.main-button');
    const mainContent = document.getElementById('main-content');
    const scrollArrow = document.querySelector('.scroll-arrow-container');
    const map = document.querySelector('.map');
    
    // Vérifier si nous sommes sur la page d'accueil (éléments présents)
    if (!titleElement || !mainButton || !mainContent) {
        // Pas sur la page d'accueil, ne pas exécuter les animations
        return;
    }
    
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    
    if (prefersReducedMotion) {
        // Afficher immédiatement tout le contenu sans animation
        if (titleElement) titleElement.classList.remove('opacity-0');
        if (mainButton) mainButton.classList.remove('opacity-0');
        if (mainContent) mainContent.classList.remove('opacity-0');
        if (map) map.classList.remove('opacity-0');
        if (scrollArrow) scrollArrow.classList.remove('opacity-0');
    } else {
        // Animation lettre par lettre pour le titre
        if (titleElement) animateTextLetterByLetter(titleElement);
        
        // Animation des autres éléments après le titre
        if (mainButton) setTimeout(() => mainButton.classList.remove('opacity-0'), 1500);
        if (scrollArrow) setTimeout(() => scrollArrow.classList.remove('opacity-0'), 1800);
        if (mainContent) setTimeout(() => mainContent.classList.remove('opacity-0'), 2000);
        if (map) setTimeout(() => map.classList.remove('opacity-0'), 2000);
    }
    
    // Fallback de sécurité - rendre tout visible si JavaScript échoue partiellement
    window.setTimeout(function() {
        document.querySelectorAll('.opacity-0').forEach(el => el.classList.remove('opacity-0'));
    }, 4000);
    
    // Initialiser le défilement fluide pour les ancres
    initSmoothScroll();
}

function animateTextLetterByLetter(element) {
    // Vérification de sécurité
    if (!element) {
        console.warn('animateTextLetterByLetter: element is null');
        return;
    }
    
    // Récupérer le texte original
    const text = element.textContent;
    
    // Vérifier que le texte existe
    if (!text) {
        console.warn('animateTextLetterByLetter: no text content found');
        return;
    }
    
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
        
        delay += 75; // Ajouter un délai pour chaque lettre
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
                const header = document.querySelector('header');
                const offset = header ? header.offsetHeight + 24 : 0;
                const targetPosition = targetElement.getBoundingClientRect().top + window.pageYOffset - offset;
                
                window.scrollTo({
                    top: Math.max(targetPosition, 0),
                    behavior: 'smooth'
                });
            }
        });
    });
}