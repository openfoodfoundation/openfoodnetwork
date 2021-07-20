RSpec.configure do |config|
  # Skip assets precompilcation if we exclude system specs.
  # For example, you can run all non-system tests via the following command:
  #
  #    rspec --tag ~type:system
  #
  # In this case, we don't need to precompile assets.
  next if config.filter.opposite.rules[:type] == "system" || config.exclude_pattern.match?(%r{spec/system})

  config.before(:suite) do
    # We can use webpack-dev-server for tests, too!
    # Useful if you working on a frontend code fixes and want to verify them via system tests.
    if Webpacker.dev_server.running?
      $stdout.puts "\n⚙️  Webpack dev server is running! Skip assets compilation.\n"
      next
    else
      $stdout.puts "\n🐢  Precompiling assets.\n"

      # The code to run webpacker:compile Rake task
      # ...
    end
  end
end

=begin

# frozen_string_literal: true

# Precompile assets before running tests to avoid timeouts.
# Do not precompile if webpack-dev-server is running (NOTE: MUST be launched with RAILS_ENV=test)
RSpec.configure do |config|
  config.before(:suite) do
    examples = RSpec.world.filtered_examples.values.flatten
    has_no_system_tests = examples.none? { |example| example.metadata[:type] == :system }

    if has_no_system_tests
      $stdout.puts "\n🚀️️  No system test selected. Skip assets compilation.\n"
      next
    end

    if Webpacker.dev_server.running?
      $stdout.puts "\n⚙️  Webpack dev server is running! Skip assets compilation.\n"
      next
    else
      $stdout.puts "\n🐢  Precompiling assets.\n"
      original_stdout = $stdout.clone
      # Use test-prof now 'cause it couldn't be monkey-patched (e.g., by Timecop or similar)
      start = Time.current
      begin
        # Silence Webpacker output
        $stdout.reopen(File.new("/dev/null", "w"))
        # next 3 lines to compile webpacker before running our test suite
        require "rake"
        Rails.application.load_tasks
        Rake::Task["webpacker:compile"].execute
      ensure
        $stdout.reopen(original_stdout)
        $stdout.puts "Finished in #{(Time.current - start).round(2)} seconds"
      end
    end
  end
end

=end

