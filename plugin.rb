# name: discourse-localized-user-fields
# about: Automatic multi-language institutional affiliation based on email domain
# version: 3.0.0
# authors: Can Bekcan

# frozen_string_literal: true

enabled_site_setting :localized_user_fields_enabled

require_relative 'lib/localized_user_fields/engine'

after_initialize do
  next unless SiteSetting.localized_user_fields_enabled

  # Yardımcı metot: Domain'e göre çevrilmiş kurum adını bulur
  module ::BekcanAffiliationHelper
    def self.resolve_for(email)
      return nil if email.blank?
      domain = email.split('@').last.to_s.downcase
      
      # I18n üzerinden mevcut dildeki karşılığını arıyoruz
      translation_key = "bekcan.institutions.#{domain}"
      translated_name = I18n.t(translation_key, default: '')
      
      translated_name.present? ? translated_name : nil
    end

    def self.update_user_affiliation(user)
      return unless user.present?
      
      # 'Affiliation' adlı kullanıcı alanının ID'sini buluyoruz
      field = UserField.find_by("LOWER(name) = ? OR LOWER(name) = ?", "affiliation", "kurum / üniversite")
      return unless field.present?

      primary_email = user.user_emails.find_by(primary: true)&.email || user.email
      institution_name = resolve_for(primary_email)

      if institution_name.present?
        # Kurum otomatik eşleştiyse kullanıcı alanına yazıyoruz
        custom_fields = user.custom_fields || {}
        field_key = "user_field_#{field.id}"
        
        if custom_fields[field_key] != institution_name
          user.custom_fields[field_key] = institution_name
          user.save_custom_fields
        end
      end
    end
  end

  # 1. Yeni kullanıcı kaydolduğunda tetiklenir
  on(:user_created) do |user|
    ::BekcanAffiliationHelper.update_user_affiliation(user)
  end

  # 2. Kullanıcı e-postası değiştiğinde tetiklenir
  on(:user_emails_changed) do |user|
    ::BekcanAffiliationHelper.update_user_affiliation(user)
  end
end