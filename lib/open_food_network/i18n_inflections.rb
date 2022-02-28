# frozen_string_literal: true

module OpenFoodNetwork
  # Pluralize or singularize words.
  #
  # We store some inflection data in locales and use a reverse lookup of a word
  # to find the plural or singular of the same word.
  #
  # Here is one example with a French user:
  #
  # - We have a product with the variant unit name "bouquet".
  # - The I18n.locale is set to :fr.
  # - The French locale contains:
  #     bunch:
  #       one: "bouquet"
  #       other: "bouquets"
  # - We create a table containing:
  #     "bouquet" => "bunch"
  #     "bouquets" => "bunch"
  # - Looking up "bouquet" gives us the I18n key "bunch".
  # - We find the right plural by calling I18n:
  #
  #     I18n.t("inflections.bunch", count: 2, default: "bouquet")
  #
  # - This returns the correct plural "bouquets".
  # - It returns the original "bouquet" if the word is missing from the locale.
  module I18nInflections
    # Make this a singleton to cache lookup tables.
    extend self

    def pluralize(word, count)
      return word if count.nil?

      key = i18n_key(word)

      return word unless key

      I18n.t(key, scope: "inflections", count: count, default: word)
    end

    private

    def i18n_key(word)
      @lookup ||= {}

      # The user may switch the locale. `I18n.t` is always using the current
      # locale and we need a lookup table for each of them.
      unless @lookup.key?(I18n.locale)
        @lookup[I18n.locale] = build_i18n_key_lookup
      end

      @lookup[I18n.locale][word.downcase]
    end

    def build_i18n_key_lookup
      lookup = {}
      I18n.t("inflections")&.each do |key, translations|
        translations.each_value do |translation|
          lookup[translation.downcase] = key
        end
      end
      lookup
    end
  end
end
