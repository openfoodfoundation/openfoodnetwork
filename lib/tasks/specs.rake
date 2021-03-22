namespace :ofn do
  namespace :specs do
    namespace :run do
      def spec_folders
        Pathname("spec/").children.select(&:directory?).map { |p|
          p.split.last.to_s
        }.reject { |p| %w(support factories javascripts performance).include?(p) }
      end

      def execute_rspec_for_pattern(pattern)
        system "bundle exec rspec --profile --pattern \"#{pattern}\""
      end

      def execute_rspec_for_spec_folder(folder)
        execute_rspec_for_pattern("spec/#{folder}/{,/*/**}/*_spec.rb")
      end

      def execute_rspec_for_spec_folders(folders)
        folders = folders.join(",") if folders.is_a?(Array)
        execute_rspec_for_pattern("spec/{#{folders}}/{,/*/**}/*_spec.rb")
      end

      desc "Run Rspec tests excluding folders"
      task :excluding_folders, [:folders] do |_task, args|
        execute_rspec_for_spec_folders(spec_folders - (args[:folders].split(",") + args.extras))
      end
    end

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
          task :rspec do
            success = execute_rspec_for_engine(engine_path)
            abort "Failure when running tests for engine \"#{engine_name}\"" unless success
          end
        end
      end

      namespace :all do
        desc "Run RSpec tests for all engines"
        task :rspec do
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
