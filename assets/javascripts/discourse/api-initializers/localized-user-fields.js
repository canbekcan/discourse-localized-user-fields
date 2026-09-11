import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.8.0", (api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  if (!siteSettings?.localized_user_fields_enabled) {
    return;
  }

  // Profil düzenleme ekranı açıldığında Affiliation kutusunu kilitler
  api.onPageChange((url) => {
    if (url.includes("/preferences/profile")) {
      setTimeout(() => {
        const affiliationInput = document.querySelector(
          ".user-field-affiliation input, .user-field-kurum---universite input"
        );
        if (affiliationInput) {
          affiliationInput.setAttribute("readonly", "readonly");
          affiliationInput.style.backgroundColor = "var(--primary-very-low, #f4f4f4)";
          affiliationInput.style.cursor = "not-allowed";
        }
      }, 300);
    }
  });
});