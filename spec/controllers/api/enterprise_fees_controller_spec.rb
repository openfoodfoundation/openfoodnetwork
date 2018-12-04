require 'spec_helper'

module Api
  describe EnterpriseFeesController, type: :controller do
    include AuthenticationWorkflow

    let!(:unreferenced_fee) { create(:enterprise_fee) }
    let!(:referenced_fee) { create(:enterprise_fee) }
    let(:product) { create(:product) }
    let(:distributor) { create(:distributor_enterprise) }
    let!(:product_distribution) { create(:product_distribution, product: product, distributor: distributor, enterprise_fee: referenced_fee) }
    let(:current_user) { create(:admin_user) }

    before do
      allow(controller).to receive(:spree_current_user) { current_user }
    end

    describe "destroy" do
      it "removes the fee" do
        expect { spree_delete :destroy, id: unreferenced_fee.id, format: :json }
          .to change { EnterpriseFee.count }.by -1
      end

      context "when the fee is referenced by a product distribution" do
        it "does not remove the fee" do
          spree_delete :destroy, id: referenced_fee.id, format: :json
          expect(response.status).to eq 403
          expect(response.body).to match(/That enterprise fee cannot be deleted/)
          expect(referenced_fee.reload).to eq(referenced_fee)
        end
      end
    end
  end
end
