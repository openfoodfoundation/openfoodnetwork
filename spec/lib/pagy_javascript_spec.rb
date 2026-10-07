# frozen_string_literal: true

RSpec.describe "pagy.mjs" do
  it "matches the version shipped with the pagy gem" do
    vendored = Rails.root.join("app/webpacker/js/pagy.mjs").read
    shipped = Pagy::ROOT.join("javascripts/pagy.mjs").read

    expect(vendored).to eq(shipped),
                        "Run `bundle exec rake pagy:sync:javascript` after upgrading pagy"
  end
end
