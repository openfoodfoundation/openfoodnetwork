# frozen_string_literal: true

RSpec.describe SubscriptionLineItem, model: true do
  describe "validations" do
    it "requires a subscription" do
      expect(subject).to belong_to :subscription
    end

    it "requires a variant" do
      expect(subject).to belong_to :variant
    end

    it "requires a integer for quantity" do
      expect(subject).to validate_numericality_of(:quantity).only_integer
    end
  end
end
