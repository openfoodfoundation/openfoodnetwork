# frozen_string_literal: true

class I18nDigests
  class << self
    def build_digests(available_locales)
      available_locales.each do |locale|
        i18n_digests[locale.to_sym] = locale_file_digest(locale)
      end
    end

    def for_locale(locale)
      i18n_digests[locale.to_sym]
    end

    private

    def i18n_digests
      Rails.application.config.x.i18n_digests
    end

    def locale_file_digest(locale)
      Digest::MD5.hexdigest(Rails.root.join("config/locales/#{locale}.yml").read)
    end
  end
end
