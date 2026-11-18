# frozen_string_literal: true

require "spec_helper"
require "open3"

# The documentation in swagger/v1.yaml is generated from the request specs in
# this folder. This spec generates it again and fails if it changed. The
# updated file is then already on disk, so you can review and commit it, and
# running this spec again passes.
RSpec.describe "API v1 documentation" do
  let(:docs) { Rails.root.join("swagger/v1.yaml") }

  it "is up to date" do
    committed_docs = docs.read

    # Coverage is reported by this run, not the nested one.
    output, status = Open3.capture2e(
      { "COVERAGE" => nil },
      "./script/rswag", "spec/requests/api/v1/",
      chdir: Rails.root.to_s,
    )

    expect(status).to be_success, output
    expect(docs.read == committed_docs).to be(true), <<~MESSAGE
      The API documentation changed. Review it with `git diff swagger/v1.yaml`
      and commit it if the changes are intended.
    MESSAGE
  end
end
