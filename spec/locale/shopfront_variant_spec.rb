# frozen_string_literal: true

require 'spec_helper'

# Verifies that the remaining_in_stock string supports Rails/i18n-js pluralization so
# that translators can provide separate singular and plural forms (e.g. French: "produit
# restant" vs "produits restants").
RSpec.describe "js.shopfront.variant.remaining_in_stock i18n key" do
  it "returns the correct string when count is 1 (singular)" do
    expect(I18n.t("js.shopfront.variant.remaining_in_stock", count: 1)).to eq("Only 1 left")
  end

  it "returns the correct string when count is 2 (plural)" do
    expect(I18n.t("js.shopfront.variant.remaining_in_stock", count: 2)).to eq("Only 2 left")
  end
end
