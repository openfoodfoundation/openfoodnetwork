require 'spec_helper'

describe Spree::Admin::OrdersController do
  let!(:order) { create(:order) }

  context "updating an order with line items" do
    let(:line_item) { create(:line_item) }
    before { login_as_admin }

    it "updates distribution charges" do
      order.line_items << line_item
      order.save
      Spree::Order.any_instance.should_receive(:update_distribution_charge!)
      spree_put :update, {
        id: order,
        order: {
          number: order.number,
          distributor_id: order.distributor_id,
          order_cycle_id: order.order_cycle_id,
          line_items_attributes: [
            {
              id: line_item.id,
              quantity: line_item.quantity
            }
          ]
        }
      }
    end
  end
end
