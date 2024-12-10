document.addEventListener("DOMContentLoaded", () => {
  const backToTopButton = document.querySelector(".back-to-top");

  backToTopButton.addEventListener("click", (e) => {
    e.preventDefault();

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  });
});
