# From: https://robots.thoughtbot.com/better-tests-through-internationalization

I18n.exception_handler = lambda do |exception, locale, key, options|
  raise "missing translation: #{key}"
end
