require 'spec_helper'

module Spree
  describe Order do
    let(:order) { Order.create }
    let(:shirt) { create(:variant) }

    pending "adds item to cart" do
      # The original spec here used Spree::Promotions, and doesn't currently work with those bits removed.
      # After fees are adjusted we should update this test to check fees are correctly applied.
      let(:calculator) { Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10) }

      before { order.contents.add(shirt, 1) }

      context "item quantity changes" do
        it "recalculates order adjustments" do
          expect {
            order.contents.add(shirt, 3)
          }.to change { order.adjustments.eligible.pluck(:amount) }
        end
      end
    end
  end
end
