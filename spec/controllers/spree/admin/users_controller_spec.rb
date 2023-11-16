# frozen_string_literal: true

require 'spec_helper'

describe Spree::Admin::UsersController do
  context '#authorize_admin' do
    let(:user) { create(:user) }
    let(:test_user) { create(:user) }

    before do
      allow(controller).to receive_messages spree_current_user: user
      allow(Spree::User).to receive(:find).with(test_user.id.to_s).and_return(test_user)
      user.spree_roles.clear
    end

    it 'should grant access to users with an admin role' do
      user.spree_roles << Spree::Role.find_or_create_by(name: 'admin')
      spree_post :index
      expect(response).to render_template :index
    end

    it "allows admins to update a user's show api key view" do
      user.spree_roles << Spree::Role.find_or_create_by(name: 'admin')
      spree_put :update, id: test_user.id, user: { show_api_key_view: true }
      expect(response).to redirect_to spree.edit_admin_user_path(test_user)
    end

    it "re-renders the edit form if error" do
      user.spree_roles << Spree::Role.find_or_create_by(name: 'admin')
      spree_put :update, id: test_user.id, user: { password: "blah", password_confirmation: "" }

      expect(response).to render_template :edit
    end

    it 'should deny access to users without an admin role' do
      allow(user).to receive_messages has_spree_role?: false
      spree_post :index
      expect(response).to redirect_to('/unauthorized')
    end
  end

  describe "#accept_terms_of_services" do
    let(:user) { create(:user) }

    before do
      allow(controller).to receive_messages spree_current_user: user
      user.spree_roles << Spree::Role.find_or_create_by(name: 'admin')
    end

    it "updates terms_of_service_accepted_at" do
      expect do
        spree_post :accept_terms_of_services, id: user.id
      end.to change { user.reload.terms_of_service_accepted_at }

      expect(response).to have_http_status(:ok)
    end

    context "when something goes wrong" do
      it "returns unprocessable entity" do
        # mock update to make it fails
        allow(user).to receive(:update).and_return(false)
        allow(Spree::User).to receive(:find).and_return(user)

        spree_post :accept_terms_of_services, id: user.id

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
