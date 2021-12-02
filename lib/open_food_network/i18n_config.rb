# frozen_string_literal: true

module OpenFoodNetwork
  # Provides access to the language settings.
  # Currently, language settings are read from the environment.
  # See: .env[.*] files.
  class I18nConfig
    # Users don't need to select the already selected locale.
    def self.locale_options
      selectable_locales - [I18n.locale.to_s]
    end

    # Locales that can be selected by users.
    def self.selectable_locales
      ENV["AVAILABLE_LOCALES"]&.split(/[\s,]+/) || []
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
