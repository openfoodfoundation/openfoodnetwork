require 'spec_helper'

module Api
  describe EnterpriseFeesController, type: :controller do
    include AuthenticationWorkflow

    let(:fee1) { create(:enterprise_fee) }
    let(:fee2) { create(:enterprise_fee) }
    let(:product) { create(:product) }
    let(:distributor) { create(:distributor_enterprise) }
    let!(:product_distribution) { create(:product_distribution, product: product, distributor: distributor, enterprise_fee: fee2) }
    let(:current_user) { create(:admin_user) }

    before do
      allow(controller).to receive(:spree_current_user) { current_user }
    end

    describe "destroy" do
      it "removes the fee" do
        spree_delete :destroy, id: fee1.id, format: :json
        puts "#" * 50
        puts response.body
        expect(response).to be_success
      end

      context "when the fee is referenced by a product distribution" do
        it "should render 403" do
          spree_delete :destroy, id: fee2.id, format: :json
          expect(response.status).to eq 403
        end

        it "should display the correct error message" do
          spree_delete :destroy, id: fee2.id, format: :json
          expect(response.body).to match(/That enterprise fee cannot be deleted/)
        end
      end
    end
  end
end
