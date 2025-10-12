document.addEventListener('turbo:load', function() {
    const dyslexicFontCheckbox = document.getElementById('user_dyslexic_font');
    
    if (dyslexicFontCheckbox) {
      // Appliquer immédiatement en fonction de l'état initial
      if (dyslexicFontCheckbox.checked) {
        document.body.classList.add('dyslexic-font-enabled');
      }
      
      // Écouter les changements de la checkbox
      dyslexicFontCheckbox.addEventListener('change', function() {
        if (this.checked) {
          document.body.classList.add('dyslexic-font-enabled');
        } else {
          document.body.classList.remove('dyslexic-font-enabled');
        }
      });
    }
  });