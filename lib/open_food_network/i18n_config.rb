module OpenFoodNetwork
  # Provides access to the language settings.
  # Currently, language settings are read from the environment.
  # See: config/application.yml
  class I18nConfig
    def self.selectable_locales
      ENV["AVAILABLE_LOCALES"].andand.split(/[\s,]+/) || []
    end

    def self.available_locales
      (selectable_locales + [default_locale, 'en']).uniq
    end

    def self.default_locale
      ENV["LOCALE"] || ENV["I18N_LOCALE"] || source_locale
    end

    def self.source_locale
      "en"
    end
  end
end
