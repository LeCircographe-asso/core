document.addEventListener('DOMContentLoaded', () => {
    const flash = document.querySelector('.flash');
    if (flash) {
      setTimeout(() => {
        flash.style.display = 'none';
      }, 1500);
    }
  });