require 'spec_helper'

describe TagRule::DiscountOrder, type: :model do
  let!(:tag_rule) { create(:tag_rule) }

  pending "determining relevance based on additional requirements" do
    let(:subject) { double(:subject) }

    before do
      tag_rule.context = {subject: subject}
      allow(tag_rule).to receive(:customer_tags_match?) { true }
      allow(subject).to receive(:class) { Spree::Order }
    end

    context "when already_applied? returns false" do
      before { expect(tag_rule).to receive(:already_applied?) { false } }

      it "returns true" do
        expect(tag_rule.send(:relevant?)).to be true
      end
    end

    context "when already_applied? returns true" do
      before { expect(tag_rule).to receive(:already_applied?) { true } }

      it "returns false immediately" do
        expect(tag_rule.send(:relevant?)).to be false
      end
    end
  end

  pending "determining whether a the rule has already been applied to an order" do
    let!(:order) { create(:order) }
    let!(:adjustment) { order.adjustments.create({:amount => 12.34, :source => order, :originator => tag_rule, :label => 'discount' }, :without_protection => true) }

    before do
      tag_rule.context = {subject: order}
    end

    context "where adjustments originating from the rule already exist" do
      it { expect(tag_rule.send(:already_applied?)).to be true}
    end

    context "where existing adjustments originate from other rules" do
      before { adjustment.update_attribute(:originator_id,create(:tag_rule).id) }
      it { expect(tag_rule.send(:already_applied?)).to be false}
    end
  end

  pending "applying the rule" do
    # Assume that all validation is done by the TagRule base class

    let!(:line_item) { create(:line_item, price: 100.00) }
    let!(:order) { line_item.order }

    before do
      order.update_distribution_charge!
      tag_rule.calculator.update_attribute(:preferred_flat_percent, -10.00)
      tag_rule.context = {subject: order}
    end

    context "in a simple scenario" do
      let(:adjustment) { order.reload.adjustments.where(originator_id: tag_rule, originator_type: "TagRule").first }

      it "creates a new adjustment on the order" do
        tag_rule.send(:apply!)
        expect(adjustment).to be_a Spree::Adjustment
        expect(adjustment.amount).to eq -10.00
        expect(adjustment.label).to eq "Discount"
        expect(order.adjustment_total).to eq -10.00
        expect(order.total).to eq 90.00
      end
    end

    context "when shipping charges apply" do
      let!(:shipping_method) { create(:shipping_method, calculator: Spree::Calculator::FlatRate.new( preferred_amount: 25.00 ) ) }
      before do
        shipping_method.create_adjustment("Shipping", order, order, true)
      end

      let(:adjustment) { order.reload.adjustments.where(originator_id: tag_rule, originator_type: "TagRule").first }

      it "the adjustment is made on line item total, ie. ignores the shipping amount" do
        tag_rule.send(:apply!)
        expect(adjustment).to be_a Spree::Adjustment
        expect(adjustment.amount).to eq -10.00
        expect(adjustment.label).to eq "Discount"
        expect(order.adjustment_total).to eq 15.00
        expect(order.total).to eq 115.00
      end
    end
  end
end
