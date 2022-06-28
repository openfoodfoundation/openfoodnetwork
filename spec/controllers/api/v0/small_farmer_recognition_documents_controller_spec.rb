# frozen_string_literal: true

require "spec_helper"

module Api
  describe V0::SmallFarmerRecognitionDocumentsController, type: :controller do
    include AuthenticationHelper
    include FileHelper

    let(:enterprise_owner) { create(:user) }
    let(:enterprise) do
      create(:enterprise, :with_small_farmer_recognition_document, owner: enterprise_owner )
    end
    let(:enterprise_manager) { create(:user, enterprises: [enterprise]) }

    describe "removing small farmer document recognition file" do
      before do
        allow(controller).to receive(:spree_current_user) { current_user }
      end

      context "as manager" do
        let(:current_user) { enterprise_manager }

        it "removes small farmer recognition document file" do
          spree_delete :destroy, enterprise_id: enterprise

          expect(response.status).to eq 200
          expect(json_response["id"]).to eq enterprise.id
          enterprise.reload
          expect(enterprise.small_farmer_recognition_document).to_not be_attached
        end

        context "when small farmer recognition document file does not exist" do
          before do
            enterprise.update small_farmer_recognition_document: nil
          end

          it "responds with error" do
            spree_delete :destroy, enterprise_id: enterprise

            expect(response.status).to eq(409)
            expect(json_response["error"])
              .to eq(
                I18n.t("api.enterprise_small_farmer_recognition_document."\
                       "destroy_attachment_does_not_exist")
              )
          end
        end
      end
    end
  end
end
