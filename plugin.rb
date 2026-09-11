# frozen_string_literal: true

# name: discourse-localized-user-fields
# about: Automatic institutional affiliation and multi-language support for user fields
# version: 3.5.0
# authors: Can Bekcan

enabled_site_setting :localized_user_fields_enabled

after_initialize do
  next unless SiteSetting.localized_user_fields_enabled

  module ::BekcanAcademicFieldsManager
    def self.sync_fields_and_options!
      # 1. Academic Title (Dropdown)
      title_field = UserField.find_by("LOWER(name) IN (?)", ["academic title", "akademik unvan"])
      unless title_field
        title_field = UserField.create!(
          name: "Academic Title",
          description: "Select your academic title from the list.",
          field_type: "dropdown",
          editable: true,
          required: true,
          show_on_profile: true,
          show_on_user_card: true
        )
      end

      # Unvanları dil dosyasından çekip veritabanıyla tam eşitleme
      raw_titles = I18n.t("bekcan.academic_titles", default: [])
      target_titles = raw_titles.is_a?(Array) ? raw_titles.map(&:to_s).reject(&:blank?) : []

      if title_field.field_type == "dropdown" && target_titles.present?
        existing_options = title_field.user_field_options.to_a
        existing_values = existing_options.map(&:value)

        (target_titles - existing_values).each do |val|
          title_field.user_field_options.create!(value: val)
        end

        existing_options.each do |opt|
          opt.destroy! unless target_titles.include?(opt.value)
        end
      end

      # 2. Affiliation (Text - Formda görünmesi için editable: true, arka planda kilitli)
      affiliation_field = UserField.find_by("LOWER(name) IN (?)", ["affiliation", "kurum / üniversite"])
      if affiliation_field
        affiliation_field.update!(
          editable: true,
          show_on_profile: true,
          show_on_user_card: true
        )
      else
        affiliation_field = UserField.create!(
          name: "Affiliation",
          description: "Institution assigned automatically based on your email domain.",
          field_type: "text",
          editable: true,
          required: false,
          show_on_profile: true,
          show_on_user_card: true
        )
      end

      affiliation_field
    rescue => e
      Rails.logger.warn("BekcanAcademicFieldsManager Setup Hatası: #{e.message}")
      nil
    end

    def self.resolve_institution(email)
      return nil if email.blank?

      domain = email.to_s.split("@").last.to_s.downcase
      translation_key = "bekcan.institutions.#{domain}"

      I18n.t(translation_key, default: "").presence
    end

    def self.update_user_affiliation(user, affiliation_field = nil)
      return if user.blank?

      field = affiliation_field || UserField.find_by("LOWER(name) IN (?)", ["affiliation", "kurum / üniversite"])
      return if field.blank?

      primary_email = user.primary_email&.email || user.email
      institution_name = resolve_institution(primary_email)
      field_key = "user_field_#{field.id}"

      target_value = institution_name.presence || nil

      if user.custom_fields[field_key] != target_value
        user.custom_fields[field_key] = target_value
        user.save_custom_fields
      end
    end

    def self.sync_all_existing_users!(affiliation_field = nil)
      field = affiliation_field || UserField.find_by("LOWER(name) IN (?)", ["affiliation", "kurum / üniversite"])
      return if field.blank?

      User.human_users.includes(:primary_email, :user_emails).find_each do |user|
        update_user_affiliation(user, field)
      end
    rescue => e
      Rails.logger.warn("BekcanAcademicFieldsManager sync Hatası: #{e.message}")
    end
  end

  affiliation_field = ::BekcanAcademicFieldsManager.sync_fields_and_options!
  ::BekcanAcademicFieldsManager.sync_all_existing_users!(affiliation_field)

  on(:user_created) do |user|
    ::BekcanAcademicFieldsManager.update_user_affiliation(user)
  end

  on(:user_emails_changed) do |user|
    ::BekcanAcademicFieldsManager.update_user_affiliation(user)
  end

  # Kullanıcı profil tercihlerini kaydettiğinde alanı zorla domain kurumuna kilitler
  on(:user_updated) do |user|
    ::BekcanAcademicFieldsManager.update_user_affiliation(user)
  end
end