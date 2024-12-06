document.addEventListener("DOMContentLoaded", () => {
  const backToTopButton = document.querySelector(".back-to-top_css");

  backToTopButton.addEventListener("click", (e) => {
    e.preventDefault();

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  });
});
