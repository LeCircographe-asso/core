document.addEventListener("turbo:load", function () {
    initFadeInAnimations();
});

function initFadeInAnimations() {
    const fadeElements = document.querySelectorAll(".fade-in");

    if (fadeElements.length === 0) return; // Évite d'exécuter le script s'il n'y a aucun élément à animer

    const observer = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add("visible");
                observer.unobserve(entry.target); // Arrête d'observer une fois l'animation déclenchée
            }
        });
    }, { threshold: 0.1 });

    fadeElements.forEach(el => observer.observe(el));
}

