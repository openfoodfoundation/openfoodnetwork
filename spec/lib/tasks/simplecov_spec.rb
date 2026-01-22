# frozen_string_literal: true

RSpec.describe "simplecov.rake" do
  describe "simplecov:collate_results" do
    context "when there are reports to merge" do
      let(:input_dir) { Rails.root.join("spec/fixtures/simplecov") }

      it "creates a new combined report" do
        Dir.mktmpdir do |tmp_dir|
          output_dir = File.join(tmp_dir, "output")

          task_name = "simplecov:collate_results[#{input_dir},#{output_dir}]"

          expect {
            if ENV["COVERAGE"]
              # Start task in a new process to not mess with our coverage report.
              `bundle exec rake #{task_name}`
            else
              # Use the quick standard invocation in dev.
              invoke_task(task_name)
            end
          }.to change { Dir.exist?(output_dir) }.
            from(false).
            to(true).

            and change { File.exist?(File.join(output_dir, "index.html")) }.
            from(false).
            to(true).

            and change { File.exist?(File.join(output_dir, "coverage.json")) }.
            from(false).
            to(true)
        end
      end
    end
  end
end
