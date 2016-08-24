require 'spec_helper'

describe StandingOrder, type: :model do
  let!(:standing_order) { create(:standing_order) }

  describe "validations" do
    it "requires a shop" do
      expect(standing_order).to validate_presence_of :shop
    end

    it "requires a customer" do
      expect(standing_order).to validate_presence_of :customer
    end

    it "requires a schedule" do
      expect(standing_order).to validate_presence_of :schedule
    end

    it "requires a payment_method" do
      expect(standing_order).to validate_presence_of :payment_method
    end

    it "requires a shipping_method" do
      expect(standing_order).to validate_presence_of :shipping_method
    end

    it "requires a begins_at date" do
      expect(standing_order).to validate_presence_of :begins_at
    end
  end
end
