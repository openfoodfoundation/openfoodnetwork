Bugsnag.configure do |config|
  config.api_key = ENV['BUGSNAG_API_KEY']
  config.release_stage = ENV['RAILS_ENV']

  release_stages_to_notify = if ENV['RAILS_ENV'].in? %w(test development)
                                nil
                             else
                               Array[ENV['RAILS_ENV']]
                             end
  config.notify_release_stages = release_stages_to_notify
end
