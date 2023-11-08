# Bugsnag will notify for any environment that the gem is installed (see Gemfile)
if defined? Bugsnag
  Bugsnag.configure do |config|
    config.api_key = ENV['BUGSNAG_API_KEY']
  end
end
