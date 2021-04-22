# frozen_string_literal: true

require 'spec_helper'

module Api
  describe V0::EnterpriseFeesController, type: :controller do
    include AuthenticationHelper

    let!(:unreferenced_fee) { create(:enterprise_fee) }
    let!(:referenced_fee) { create(:enterprise_fee) }
    let(:product) { create(:product) }
    let(:distributor) { create(:distributor_enterprise) }
    let(:current_user) { create(:admin_user) }

    before do
      allow(controller).to receive(:spree_current_user) { current_user }
    end

    describe "destroy" do
      it "removes the fee" do
        expect { spree_delete :destroy, id: unreferenced_fee.id, format: :json }
          .to change { EnterpriseFee.count }.by(-1)
      end
    end
  end
end
