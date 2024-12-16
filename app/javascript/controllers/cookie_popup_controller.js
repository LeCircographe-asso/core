document.addEventListener("DOMContentLoaded", () => {
  const cookiePopup = document.getElementById("cookie-popup");
  const acceptCookiesButton = document.getElementById("accept-cookies");

  if (!localStorage.getItem("cookiesAccepted")) {
    cookiePopup.classList.remove("hidden");
  }

  acceptCookiesButton.addEventListener("click", () => {
    localStorage.setItem("cookiesAccepted", "true");
    cookiePopup.classList.add("hidden");
  });
});
