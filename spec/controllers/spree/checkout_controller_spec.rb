require 'spec_helper'
require 'spree/api/testing_support/helpers'
require 'support/request/authentication_workflow'


describe Spree::CheckoutController, type: :controller do
  context 'rendering edit from within spree for the current checkout state' do
    let(:order) { controller.current_order(true) }
    let(:user) { create(:user) }

    before do
      create(:line_item, order: order)

      allow(controller).to receive(:skip_state_validation?) { true }
      allow(controller).to receive(:spree_current_user) { user }
    end

    it "redirects to the OFN checkout page" do
      expect(spree_get(:edit)).to redirect_to checkout_path
    end
  end
end
