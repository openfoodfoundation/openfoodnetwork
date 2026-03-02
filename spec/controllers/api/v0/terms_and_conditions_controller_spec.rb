# frozen_string_literal: true

module Api
  RSpec.describe V0::TermsAndConditionsController do
    include AuthenticationHelper
    include FileHelper

    let(:enterprise_owner) { create(:user) }
    let(:enterprise) { create(:enterprise, owner: enterprise_owner ) }
    let(:enterprise_manager) { create(:user, enterprises: [enterprise]) }

    describe "removing terms and conditions file" do
      let(:terms_and_conditions_file) { terms_pdf_file }
      let(:enterprise) { create(:enterprise, owner: enterprise_owner) }

      before do
        allow(controller).to receive(:spree_current_user) { current_user }
        enterprise.update!(terms_and_conditions: terms_and_conditions_file)
      end

      context "as manager" do
        let(:current_user) { enterprise_manager }

        it "removes terms and conditions file" do
          spree_delete :destroy, enterprise_id: enterprise

          expect(response).to have_http_status :ok
          expect(json_response["id"]).to eq enterprise.id
          enterprise.reload
          expect(enterprise.terms_and_conditions).not_to be_attached
        end

        context "when terms and conditions file does not exist" do
          let(:enterprise) { create(:enterprise, owner: enterprise_owner) }

          before do
            enterprise.update terms_and_conditions: nil
          end

          it "responds with error" do
            spree_delete :destroy, enterprise_id: enterprise

            expect(response).to have_http_status(:conflict)
            expect(json_response['error']).to eq 'Terms and Conditions file does not exist'
          end
        end
      end
    end
  end
end
