# plugins/discourse-bekcan-localized-user-fields/plugin.rb
after_initialize do
  module ::BekcanLocalizedUserFields
    def name
      I18n.t("bekcan.user_fields.#{super.parameterize.underscore}.name", default: super)
    end

    def description
      I18n.t("bekcan.user_fields.#{name.parameterize.underscore}.description", default: super)
    end
  end

  UserField.prepend(::BekcanLocalizedUserFields)
end