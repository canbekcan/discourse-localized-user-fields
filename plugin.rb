# frozen_string_literal: true

# name: discourse-localized-user-fields
# about: Automatic institutional affiliation and multi-language support for user fields
# version: 3.1.0
# authors: Can Bekcan

enabled_site_setting :localized_user_fields_enabled

after_initialize do
  next unless SiteSetting.localized_user_fields_enabled

  module ::BekcanAffiliationHelper
    def self.resolve_for(email)
      return nil if email.blank?

      domain = email.to_s.split("@").last.to_s.downcase
      translation_key = "bekcan.institutions.#{domain}"

      I18n.t(translation_key, default: "").presence
    end

    def self.update_user_affiliation(user)
      return if user.blank?

      field = UserField.find_by("LOWER(name) IN (?)", ["affiliation", "kurum / üniversite"])
      return if field.blank?

      primary_email = user.primary_email&.email || user.email
      institution_name = resolve_for(primary_email)

      return if institution_name.blank?

      field_key = "user_field_#{field.id}"
      user.custom_fields[field_key] = institution_name
      user.save_custom_fields
    end
  end

  on(:user_created) do |user|
    ::BekcanAffiliationHelper.update_user_affiliation(user)
  end

  on(:user_emails_changed) do |user|
    ::BekcanAffiliationHelper.update_user_affiliation(user)
  end
end