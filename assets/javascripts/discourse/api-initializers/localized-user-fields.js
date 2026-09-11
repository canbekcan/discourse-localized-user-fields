import { apiInitializer } from "discourse/lib/api";
import I18n from "discourse-i18n";

export default apiInitializer("1.8.0", (api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  if (!siteSettings?.localized_user_fields_enabled) {
    return;
  }

  // Model override yerine sadece serializer çıktısı veya DOM element düzeyinde etiket düzenlemesi
  api.decorateWidget?.("user-field:after", (helper) => {
    const field = helper.attrs?.field;
    if (!field?.name) {
      return;
    }

    const key = field.name.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "");
    const translatedName = I18n.t(`bekcan.user_fields.${key}.name`, { defaultValue: "" });

    if (translatedName) {
      field.name = translatedName;
    }
  });
});