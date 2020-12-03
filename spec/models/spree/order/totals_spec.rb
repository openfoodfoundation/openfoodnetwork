
require 'spec_helper'

module Spree
  describe Order do
    let(:order) { Order.create }
    let(:shirt) { create(:variant) }

    context "adds item to cart" do
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
