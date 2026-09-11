// assets/javascripts/discourse/api-initializers/localized-user-fields.js
import { apiInitializer } from 'discourse/lib/api';
import I18n from 'discourse-i18n';

export default apiInitializer('1.8.0', (api) => {
  api.modifyClass('model:user-field', {
    pluginId: 'bekcan-localized-user-fields',
    
    get name() {
      const originalName = this._super(...arguments);
      if (!originalName) return originalName;
      const key = originalName.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
      return I18n.t(`bekcan.user_fields.${key}.name`, { defaultValue: originalName });
    },

    get description() {
      const originalName = this.name;
      if (!originalName) return this._super(...arguments);
      const key = originalName.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
      return I18n.t(`bekcan.user_fields.${key}.description`, { defaultValue: this._super(...arguments) });
    }
  });
});