require 'spec_helper'

describe StandingLineItem, model: true do
  describe "validations" do
    it "requires a standing_order" do
      expect(subject).to validate_presence_of :standing_order
    end

    it "requires a variant" do
      expect(subject).to validate_presence_of :variant
    end

    it "requires a integer for quantity" do
      expect(subject).to validate_numericality_of(:quantity).only_integer
    end
  end
end
