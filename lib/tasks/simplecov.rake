# frozen_string_literal: true

namespace :simplecov do
  desc "Collates all result sets produced during parallel test runs"
  task :collate_results, # rubocop:disable Rails/RakeEnvironment doesn't need the full env
       [:path_to_results, :coverage_dir] do |_t, args|
    # This code is covered by a spec but trying to measure the code coverage of
    # the spec breaks the coverage report. We need to ignore it to avoid warnings.
    # :nocov:
    require "simplecov"
    require "undercover/simplecov_formatter"

    path_to_results = args[:path_to_results].presence || "tmp/simplecov"
    output_path = args[:coverage_dir].presence || "coverage"

    result_files = Dir[File.join(path_to_results, "**", ".resultset.json")]
    if result_files.empty?
      puts "No SimpleCov results found in #{path_to_results}. Skipping collation."
      next
    end

    SimpleCov.collate result_files, "rails" do
      formatter(SimpleCov::Formatter::HTMLFormatter)
      coverage_dir(output_path)
    end

    SimpleCov.collate result_files, "rails" do
      formatter(SimpleCov::Formatter::Undercover)
      coverage_dir(output_path)
    end
    # :nocov:
  end
end
