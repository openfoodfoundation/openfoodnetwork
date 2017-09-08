require 'spec_helper'

module Spree
  describe Spree::Api::LineItemsController, type: :controller do
    render_views

    before do
      stub_authentication!
      Spree.user_class.stub :find_by_spree_api_key => current_api_user
    end

    def self.make_simple_data!
      let!(:order) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.zone.now) }
      let!(:line_item) { FactoryGirl.create(:line_item, order: order, final_weight_volume: 500) }
    end

    #test that when a line item is updated, an order's fees are updated too
    context "as an admin user" do
      sign_in_as_admin!
      make_simple_data!

      context "as a line item is updated" do
        it "update distribution charge on the order" do
          line_item_params = { order_id: order.number, id: line_item.id, line_item: { id: line_item.id, final_weight_volume: 520 }, format: :json}
          allow(controller).to receive(:order) { order }
          expect(order).to receive(:update_distribution_charge!)
          spree_post :update, line_item_params
        end
      end
    end
  end
end
