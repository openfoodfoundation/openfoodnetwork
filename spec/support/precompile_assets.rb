# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:all) do
    # We can use webpack-dev-server for tests, too!
    # Useful if you working on a frontend code fixes and want to verify them via system tests.
    next if Webpacker.dev_server.running?

    specs_needing_assets = %i[controller feature mailer request system view]
    examples = RSpec.world.filtered_examples.values.flatten
    types = examples.map(&:metadata).pluck(:type).uniq

    if types.intersect?(specs_needing_assets)
      $stdout.puts "\n Checking if assets need compiling.\n"
      Webpacker.compile
    end
  end
end
