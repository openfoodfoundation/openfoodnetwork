# frozen_string_literal: true

require "spec_helper"

module Api
  describe V0::LogosController, type: :controller do
    include AuthenticationHelper
    include FileHelper

    let(:admin_user) { create(:admin_user) }
    let(:enterprise_owner) { create(:user) }
    let(:enterprise) { create(:enterprise, owner: enterprise_owner ) }
    let(:enterprise_manager) { create(:user, enterprise_limit: 10, enterprises: [enterprise]) }
    let(:other_enterprise_owner) { create(:user) }
    let(:other_enterprise) { create(:enterprise, owner: other_enterprise_owner ) }
    let(:other_enterprise_manager) {
      create(:user, enterprise_limit: 10, enterprises: [other_enterprise])
    }

    describe "removing logo" do
      let(:image) { Rack::Test::UploadedFile.new(black_logo_file, "image/png") }

      let(:enterprise) { create(:enterprise, owner: enterprise_owner, logo: image) }

      before do
        allow(controller).to receive(:spree_current_user) { current_user }
      end

      context "as manager" do
        let(:current_user) { enterprise_manager }

        it "removes logo" do
          spree_delete :destroy, enterprise_id: enterprise

          expect(response.status).to eq 200
          expect(json_response["id"]).to eq enterprise.id
          enterprise.reload
          expect(enterprise.logo).to_not be_attached
        end

        context "when logo does not exist" do
          let(:enterprise) { create(:enterprise, owner: enterprise_owner, logo: nil) }

          it "responds with error" do
            spree_delete :destroy, enterprise_id: enterprise

            expect(response.status).to eq(409)
            expect(json_response['error']).to eq 'Logo does not exist'
          end
        end
      end

      context "as owner" do
        let(:current_user) { enterprise_owner }

        it "allows removal of logo" do
          spree_delete :destroy, enterprise_id: enterprise
          expect(response.status).to eq 200
        end
      end

      context "as super admin" do
        let(:current_user) { admin_user }

        it "allows removal of logo" do
          spree_delete :destroy, enterprise_id: enterprise
          expect(response.status).to eq 200
        end
      end

      context "as manager of other enterprise" do
        let(:current_user) { other_enterprise_manager }

        it "does not allow removal of logo" do
          spree_delete :destroy, enterprise_id: enterprise
          expect(response.status).to eq(401)
          enterprise.reload
          expect(enterprise.logo).to be_attached
        end
      end

      context "as owner of other enterprise" do
        let(:current_user) { other_enterprise_owner }

        it "does not allow removal of logo" do
          spree_delete :destroy, enterprise_id: enterprise
          expect(response.status).to eq(401)
          enterprise.reload
          expect(enterprise.logo).to be_attached
        end
      end
    end
  end
end
