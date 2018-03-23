module OpenFoodNetwork
  # Provides access to the language settings.
  # Currently, language settings are read from the environment.
  # See: config/application.yml
  class I18nConfig
    # Locales that can be selected by users.
    def self.selectable_locales
      ENV["AVAILABLE_LOCALES"].andand.split(/[\s,]+/) || []
    end

    # All locales that can be accessed by the application, including fallbacks.
    def self.available_locales
      (selectable_locales + [default_locale, source_locale]).uniq
    end

    # The default locale that is used when the user doesn't have a preference.
    def self.default_locale
      ENV["LOCALE"] || ENV["I18N_LOCALE"] || source_locale
    end

    # This locale is changed with the code and should always be complete.
    # All translations are done from this locale.
    def self.source_locale
      "en"
    end
  end
end
