# This is copied from https://github.com/fnando/i18n-js/blob/master/lib/i18n/js.rb
# As in spree core en.yml there are translations -
# en:
#   no: "No"
#   yes: "Yes"
# Which become to true and false and those have no #to_sym method
# TODO - remove this after spree core locales are fixed

module I18n
  module JS
    # Filter translations according to the specified scope.
    def self.filter(translations, scopes)
      scopes = scopes.split(".") if scopes.is_a?(String)
      scopes = scopes.clone
      scope = scopes.shift
      if scope == "*"
        results = {}
        translations.each do |scope, translations|
          tmp = scopes.empty? ? translations : filter(translations, scopes)
          scope_symbol = scope.respond_to?(:to_sym) ? scope.to_sym : scope.to_s.to_sym
          results[scope_symbol] = tmp unless tmp.nil?
        end
        return results
      elsif translations.respond_to?(:key?) && translations.key?(scope.to_sym)
        return {scope.to_sym => scopes.empty? ? translations[scope.to_sym] : filter(translations[scope.to_sym], scopes)}
      end
      nil
    end
  end
end
