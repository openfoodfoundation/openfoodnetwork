# frozen_string_literal: true

# From: https://robots.thoughtbot.com/better-tests-through-internationalization

I18n.exception_handler = lambda do |_exception, _locale, key, _options|
  raise "missing translation: #{key}"
end
