# frozen_string_literal: true

require 'spec_helper'

module Admin
  describe ManagerInvitationsController, type: :controller do
    include OpenFoodNetwork::EmailHelper

    let!(:enterprise_owner) { create(:user) }
    let!(:other_enterprise_user) { create(:user) }
    let!(:existing_user) { create(:user) }
    let!(:enterprise) { create(:enterprise, owner: enterprise_owner ) }
    let!(:enterprise2) { create(:enterprise, owner: other_enterprise_user ) }
    let(:admin) { create(:admin_user) }

    describe "#create" do
      context "when given email matches an existing user" do
        before do
          allow(controller).to receive_messages spree_current_user: admin
        end

        it "returns an error" do
          spree_post :create, email: existing_user.email, enterprise_id: enterprise.id

          expect(response.status).to eq 422
          expect(json_response['errors']).to eq I18n.t('admin.enterprises.invite_manager.user_already_exists')
        end
      end

      context "signing up a new user" do
        let(:manager_invitation) { instance_double(ManagerInvitationJob) }

        before do
          setup_email
          allow(controller).to receive_messages spree_current_user: admin
        end

        it 'enqueues an invitation email' do
          allow(ManagerInvitationJob)
            .to receive(:new).with(enterprise.id, kind_of(Integer)) { manager_invitation }

          expect(Delayed::Job).to receive(:enqueue).with(manager_invitation)

          spree_post :create, email: 'un.registered@email.com', enterprise_id: enterprise.id
        end

        it "returns the user id" do
          spree_post :create, email: 'un.registered@email.com', enterprise_id: enterprise.id

          new_user = Spree::User.find_by(email: 'un.registered@email.com')
          expect(json_response['user']).to eq new_user.id
        end
      end
    end

    describe "with enterprise permissions" do
      context "as user with proper enterprise permissions" do
        before do
          setup_email
          allow(controller).to receive_messages spree_current_user: enterprise_owner
        end

        it "returns success code" do
          spree_post :create, email: 'an@email.com', enterprise_id: enterprise.id

          new_user = Spree::User.find_by(email: 'an@email.com')

          expect(new_user.reset_password_token).to_not be_nil
          expect(json_response['user']).to eq new_user.id
          expect(response.status).to eq 200
        end
      end

      context "as another enterprise user without permissions for this enterprise" do
        before do
          allow(controller).to receive_messages spree_current_user: other_enterprise_user
        end

        it "returns unauthorized response" do
          spree_post :create, email: 'another@email.com', enterprise_id: enterprise.id

          new_user = Spree::User.find_by(email: 'another@email.com')

          expect(new_user).to be_nil
          expect(response.status).to eq 302
        end
      end
    end
  end
end
