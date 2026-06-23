# frozen_string_literal: true

require 'spec_helper'

# Verifies that the remaining_in_stock string supports Rails/i18n-js pluralization so
# that translators can provide separate singular and plural forms.
RSpec.describe "js.shopfront.variant.remaining_in_stock i18n key" do
  context "in English" do
    it "returns the correct string when count is 1 (singular)" do
      expect(I18n.t("js.shopfront.variant.remaining_in_stock", count: 1)).to eq("Only 1 left")
    end

    it "returns the correct string when count is 2 (plural)" do
      expect(I18n.t("js.shopfront.variant.remaining_in_stock", count: 2)).to eq("Only 2 left")
    end
  end

  context "in en_TST (demonstrating distinct singular/plural forms)" do
    it "uses the singular form for count: 1" do
      expect(I18n.t("js.shopfront.variant.remaining_in_stock", count: 1, locale: :en_TST))
        .to eq("Only 1 item remaining")
    end

    it "uses the plural form for count: 2" do
      expect(I18n.t("js.shopfront.variant.remaining_in_stock", count: 2, locale: :en_TST))
        .to eq("Only 2 items remaining")
    end
  end
end
