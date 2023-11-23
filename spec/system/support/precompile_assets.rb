# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    # We can use webpack-dev-server for tests, too!
    # Useful if you working on a frontend code fixes and want to verify them via system tests.
    next if Webpacker.dev_server.running?

    $stdout.puts "\n Precompiling assets.\n"
    Webpacker.compile
  end
end
