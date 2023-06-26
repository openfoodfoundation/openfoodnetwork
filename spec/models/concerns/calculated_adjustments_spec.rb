# frozen_string_literal: true

require 'spec_helper'

# Its pretty difficult to test this module in isolation b/c it needs to work in conjunction
#   with an actual class that extends ActiveRecord::Base and has a corresponding table in the DB.
#   So we'll just test it using Order and ShippingMethod. These classes are including the module.
describe CalculatedAdjustments do
  let(:calculator) { build(:calculator) }
  let(:tax_rate) { Spree::TaxRate.new(calculator: calculator) }

  before do
    allow(calculator).to receive(:compute) { 10 }
    allow(calculator).to receive(:[]) { nil }
  end

  it "should add has_one :calculator relationship" do
    assert Spree::ShippingMethod.
      reflect_on_all_associations(:has_one).map(&:name).include?(:calculator)
  end

  context "#create_adjustment and its resulting adjustment" do
    let(:order) { Spree::Order.create }
    let(:target) { order }

    it "should be associated with the target" do
      expect(target.adjustments).to receive(:create)
      tax_rate.create_adjustment("foo", target)
    end

    it "should be associated with the order" do
      tax_rate.create_adjustment("foo", target)
      expect(target.adjustments.first.order_id).to eq order.id
    end

    it "should have the correct originator and an amount derived " \
       "from the calculator and supplied calculable" do
      adjustment = tax_rate.create_adjustment("foo", target)
      expect(adjustment).not_to be_nil
      expect(adjustment.amount).to eq 10
      expect(adjustment.adjustable).to eq order
      expect(adjustment.originator).to eq tax_rate
    end

    it "should be mandatory if true is supplied for that parameter" do
      adjustment = tax_rate.create_adjustment("foo", target, true)
      expect(adjustment).to be_mandatory
    end

    context "when the calculator returns 0" do
      before { allow(calculator).to receive_messages(compute: 0) }

      context "when adjustment is mandatory" do
        before { tax_rate.create_adjustment("foo", target, true) }

        it "should create an adjustment" do
          expect(Spree::Adjustment.count).to eq 1
        end
      end

      context "when adjustment is not mandatory" do
        before { tax_rate.create_adjustment("foo", target, order, false) }

        it "should not create an adjustment" do
          expect(Spree::Adjustment.count).to eq 0
        end
      end
    end
  end
end
