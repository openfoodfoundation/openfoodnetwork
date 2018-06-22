require 'spec_helper'

module Admin
  describe ManagerInvitationsController, type: :controller do
    let!(:enterprise_owner) { create(:user) }
    let!(:other_enterprise_user) { create(:user) }
    let!(:existing_user) { create(:user) }
    let!(:enterprise) { create(:enterprise, owner: enterprise_owner ) }
    let!(:enterprise2) { create(:enterprise, owner: other_enterprise_user ) }
    let(:admin) { create(:admin_user) }

    describe "#create" do
      context "when given email matches an existing user" do
        before do
          controller.stub spree_current_user: admin
        end

        it "returns an error" do
          spree_post :create, {email: existing_user.email, enterprise_id: enterprise.id}

          expect(response.status).to eq 422
          expect(json_response['errors']).to eq I18n.t('admin.enterprises.invite_manager.user_already_exists')
        end
      end

      context "signing up a new user" do
        before do
          controller.stub spree_current_user: admin
        end

        it "creates a new user, sends an invitation email, and returns the user id" do
          expect do
            spree_post :create, {email: 'un.registered@email.com', enterprise_id: enterprise.id}
          end.to enqueue_job Delayed::PerformableMethod

          new_user = Spree::User.find_by_email('un.registered@email.com')

          expect(new_user.reset_password_token).to_not be_nil
          expect(response.status).to eq 200
          expect(json_response['user']).to eq new_user.id
        end
      end
    end

    describe "with enterprise permissions" do
      context "as user with proper enterprise permissions" do
        before do
          controller.stub spree_current_user: enterprise_owner
        end

        it "returns success code" do
          spree_post :create, {email: 'an@email.com', enterprise_id: enterprise.id}

          new_user = Spree::User.find_by_email('an@email.com')

          expect(new_user.reset_password_token).to_not be_nil
          expect(json_response['user']).to eq new_user.id
          expect(response.status).to eq 200
        end
      end

      context "as another enterprise user without permissions for this enterprise" do
        before do
          controller.stub spree_current_user: other_enterprise_user
        end

        it "returns unauthorized response" do
          spree_post :create, {email: 'another@email.com', enterprise_id: enterprise.id}

          new_user = Spree::User.find_by_email('another@email.com')

          expect(new_user).to be_nil
          expect(response.status).to eq 302
        end
      end
    end
  end
end
