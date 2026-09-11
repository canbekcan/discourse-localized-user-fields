# frozen_string_literal: true

# name: discourse-localized-user-fields
# about: Automatic institutional affiliation and multi-language support for user fields
# version: 3.2.0
# authors: Can Bekcan

enabled_site_setting :localized_user_fields_enabled

after_initialize do
  next unless SiteSetting.localized_user_fields_enabled

  # 1. GEREKLİ ALANLARI OTOMATİK OLUŞTURMA (SEED)
  module ::BekcanUserFieldsSetup
    def self.ensure_fields!
      # Academic Title Alanı (Dropdown)
      title_field = UserField.find_by("LOWER(name) IN (?)", ["academic title", "akademik unvan"])
      unless title_field
        UserField.create!(
          name: "Academic Title",
          description: "Select your academic title from the list.",
          field_type: "dropdown",
          editable: true,
          required: false,
          show_on_profile: true,
          show_on_user_card: true
        )
      end

      # Affiliation / Kurum Alanı (Text - Salt Okunur/Otomatik doldurulur)
      affiliation_field = UserField.find_by("LOWER(name) IN (?)", ["affiliation", "kurum / üniversite"])
      unless affiliation_field
        UserField.create!(
          name: "Affiliation",
          description: "Your institution assigned automatically based on your email domain.",
          field_type: "text",
          editable: false, # Kullanıcı elle değiştiremez, e-postadan otomatik gelir
          required: false,
          show_on_profile: true,
          show_on_user_card: true
        )
      end
    rescue => e
      Rails.logger.warn("BekcanUserFieldsSetup Hatası: #{e.message}")
    end
  end

  # Sunucu her açıldığında alanların varlığını garanti eder
  ::BekcanUserFieldsSetup.ensure_fields!

  # 2. DOMAIN EŞLEŞTİRME VE ATAMA
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

  # 3. TETİKLEYİCİLER (Kullanıcı kaydı ve E-posta değişimi)
  on(:user_created) do |user|
    ::BekcanAffiliationHelper.update_user_affiliation(user)
  end

  on(:user_emails_changed) do |user|
    ::BekcanAffiliationHelper.update_user_affiliation(user)
  end
end