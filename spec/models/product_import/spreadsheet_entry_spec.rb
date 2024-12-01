# frozen_string_literal: false

require 'spec_helper'
RSpec.describe ProductImport::SpreadsheetEntry do
  let(:enterprise) { create(:enterprise) }
  let(:entry) {
    ProductImport::SpreadsheetEntry.new(
      "units" => "500",
      "unit_type" => "kg",
      "name" => "Tomato",
      "enterprise" => enterprise,
      "enterprise_id" => enterprise.id,
      "producer" => enterprise,
      "producer_id" => enterprise.id,
      "distributor" => enterprise,
      "price" => "1.0",
      "on_hand" => "1",
      "display_name" => display_name,
    )
  }
  let(:display_name) { "" }

  describe "#match_variant?" do
    it "returns true if matching" do
      variant = create(:variant, unit_value: 500_000)

      expect(entry.match_variant?(variant)).to be(true)
    end

    it "returns false if not machting" do
      variant = create(:variant, unit_value: 500)

      expect(entry.match_variant?(variant)).to be(false)
    end

    context "with same display_name" do
      let(:display_name) { "Good" }

      it "returns true" do
        variant = create(:variant, unit_value: 500_000, display_name: "Good")

        expect(entry.match_variant?(variant)).to be(true)
      end
    end

    context "with different display_name" do
      let(:display_name) { "Bad" }

      it "returns false" do
        variant = create(:variant, unit_value: 500_000, display_name: "Good")

        expect(entry.match_variant?(variant)).to be(false)
      end
    end
  end
end
