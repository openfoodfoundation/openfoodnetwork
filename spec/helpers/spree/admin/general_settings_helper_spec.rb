# frozen_string_literal: true

RSpec.describe Spree::Admin::GeneralSettingsHelper do
  describe "#all_units" do
    it "returns all units" do
      expect(helper.all_units).to eq(["mg", "g", "kg", "T", "oz", "lb", "mL", "cL", "dL", "L",
                                      "kL", "gal"])
    end
  end
end
