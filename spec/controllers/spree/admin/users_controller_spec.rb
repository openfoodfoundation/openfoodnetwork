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

    it "allows admins to update a user's API key" do
      user.spree_roles << Spree::Role.find_or_create_by(name: 'admin')
      expect(test_user).to receive(:generate_spree_api_key!).and_return(true)
      puts user.id
      puts test_user.id
      spree_put :generate_api_key, id: test_user.id
      expect(response).to redirect_to(spree.edit_admin_user_path(test_user))
    end

    it "allows admins to clear a user's API key" do
      user.spree_roles << Spree::Role.find_or_create_by(name: 'admin')
      expect(test_user).to receive(:clear_spree_api_key!).and_return(true)
      spree_put :clear_api_key, id: test_user.id
      expect(response).to redirect_to(spree.edit_admin_user_path(test_user))
    end

    it 'should deny access to users without an admin role' do
      allow(user).to receive_messages has_spree_role?: false
      spree_post :index
      expect(response).to redirect_to('/unauthorized')
    end
  end
end
