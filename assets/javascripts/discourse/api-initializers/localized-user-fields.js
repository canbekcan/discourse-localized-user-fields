// assets/javascripts/discourse/api-initializers/localized-user-fields.js
import { apiInitializer } from 'discourse/lib/api';
import I18n from 'discourse-i18n';

export default apiInitializer('1.8.0', (api) => {
  api.modifyClass('model:user-field', {
    pluginId: 'bekcan-localized-user-fields',
    get name() {
      const originalName = this._super(...arguments);
      const key = originalName ? originalName.toLowerCase().replace(/\s+/g, '_') : '';
      return I18n.t(`bekcan.user_fields.${key}.name`, { defaultValue: originalName });
    },
    get description() {
      const originalDesc = this._super(...arguments);
      const key = this.get('name') ? this.get('name').toLowerCase().replace(/\s+/g, '_') : '';
      return I18n.t(`bekcan.user_fields.${key}.description`, { defaultValue: originalDesc });
    }
  });
});