# frozen_string_literal: true

namespace :ofn do
  namespace :specs do
    namespace :engines do
      def detect_engine_paths
        Pathname("engines/").children.select(&:directory?)
      end

      def engine_name_for_engine(engine_path)
        engine_path.basename.to_path
      end

      def execute_rspec_for_engine(engine_path)
        system "DISABLE_KNAPSACK=true bundle exec rspec #{engine_path.expand_path}/spec"
      end

      engine_paths = detect_engine_paths

      engine_paths.each do |engine_path|
        engine_name = engine_name_for_engine(engine_path)

        namespace engine_name do
          desc "Run RSpec tests for engine \"#{engine_name}\""
          task rspec: :environment do
            success = execute_rspec_for_engine(engine_path)
            abort "Failure when running tests for engine \"#{engine_name}\"" unless success
          end
        end
      end

      namespace :all do
        desc "Run RSpec tests for all engines"
        task rspec: :environment do
          success = true

          engine_paths.each do |engine_path|
            success = !!execute_rspec_for_engine(engine_path) && success
          end

          abort "Failure encountered when running tests for engines" unless success
        end
      end

      desc "Alias for openfoodnetwork:specs:engines:all:rspec"
      task rspec: "all:rspec"
    end
  end
end
