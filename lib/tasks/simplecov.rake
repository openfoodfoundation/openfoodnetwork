# frozen_string_literal: true

namespace :simplecov do
  desc "Collates all result sets produced during parallel test runs"
  task :collate_results, # rubocop:disable Rails/RakeEnvironment doesn't need the full env
       [:path_to_results, :coverage_dir] do |_t, args|
    require "simplecov"
    require "simplecov-lcov"

    path_to_results = args[:path_to_results].presence || "tmp/simplecov"
    output_path = args[:coverage_dir].presence || "coverage"

    SimpleCov.collate Dir[File.join(path_to_results, "**", ".resultset.json")], "rails" do
      formatter(SimpleCov::Formatter::HTMLFormatter)
      coverage_dir(output_path)
    end

    SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
    SimpleCov.collate Dir[File.join(path_to_results, "**", ".resultset.json")], "rails" do
      formatter(SimpleCov::Formatter::LcovFormatter)
      coverage_dir(output_path)
    end
  end
end
