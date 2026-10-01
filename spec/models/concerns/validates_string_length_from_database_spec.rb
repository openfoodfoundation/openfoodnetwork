# frozen_string_literal: true

RSpec.describe ValidatesStringLengthFromDatabase do
  describe "string column length" do
    it "adds a too-long error when a name exceeds the database limit" do
      order_cycle = OrderCycle.new(name: "x" * 300)

      order_cycle.valid?

      expect(order_cycle.errors[:name]).to include(
        "is too long (maximum is 255 characters)"
      )
    end

    it "accepts a value within the database limit" do
      order_cycle = OrderCycle.new(name: "x" * 255)

      expect(order_cycle.errors[:name]).to be_empty
    end
  end

  describe "decimal columns" do
    it "does not validate decimal columns" do
      line_item = Spree::LineItem.new(final_weight_volume: 5.5)

      line_item.valid?

      expect(line_item.errors[:final_weight_volume]).to be_empty
    end
  end
end
