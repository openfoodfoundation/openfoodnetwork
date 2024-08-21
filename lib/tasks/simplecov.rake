# frozen_string_literal: true

namespace :simplecov do
  desc "Collates all result sets produced during parallel test runs"
  task :collate_results, # rubocop:disable Rails/RakeEnvironment doesn't need the full env
       [:path_to_results, :coverage_dir] do |_t, args|
    require "simplecov"

    path_to_results = args[:path_to_results].presence || "tmp/simple-cov"
    coverage_dir = args[:coverage_dir].presence || "coverage"

    SimpleCov.collate Dir[File.join(path_to_results, "**", ".resultset.json")], "rails" do
      formatter SimpleCov::Formatter::HTMLFormatter

      coverage_dir coverage_dir
    end
  end
end
