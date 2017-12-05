require 'spec_helper'

module Spree
  describe Spree::Api::LineItemsController, type: :controller do
    render_views

    before do
      allow(controller).to receive(:spree_current_user) { current_api_user }
    end

    #test that when a line item is updated, an order's fees are updated too
    context "as an admin user" do
      sign_in_as_admin!

      let(:order) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.zone.now) }
      let(:line_item) { FactoryGirl.create(:line_item, order: order, final_weight_volume: 500) }

      context "as a line item is updated" do
        before { allow(controller).to receive(:order) { order } }

        it "update distribution charge on the order" do
          line_item_params = {
            order_id: order.number,
            id: line_item.id,
            line_item: { id: line_item.id, final_weight_volume: 520 },
            format: :json
          }

          expect(order).to receive(:update_distribution_charge!)
          spree_post :update, line_item_params
        end
      end
    end
  end
end
