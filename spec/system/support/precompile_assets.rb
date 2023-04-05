# frozen_string_literal: true

RSpec.configure do |config|
  # Skip assets precompilcation if we exclude system specs.
  # For example, you can run all non-system tests via the following command:
  #
  #    rspec --tag ~type:system
  #
  # In this case, we don't need to precompile assets.
  next if (
    config.filter.opposite.rules[:type] == "system" ||
    config.exclude_pattern.match?(%r{spec/system})
  )

  config.before(:suite) do
    # We can use webpack-dev-server for tests, too!
    # Useful if you working on a frontend code fixes and want to verify them via system tests.
    if Webpacker.dev_server.running?
      next
    else
      $stdout.puts "\n Precompiling assets.\n"

      Webpacker.compile
    end
  end
end
