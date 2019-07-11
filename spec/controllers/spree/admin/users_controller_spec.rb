require 'spec_helper'
require 'spree/testing_support/bar_ability'

describe Spree::Admin::UsersController do
  context '#authorize_admin' do
    let(:user) { create(:user) }
    let(:test_user) { create(:user) }

    before do
      controller.stub spree_current_user: user
      Spree::User.stub(:find).with(test_user.id.to_s).and_return(test_user)
      user.spree_roles.clear
    end

    it 'should grant access to users with an admin role' do
      user.spree_roles << Spree::Role.find_or_create_by_name('admin')
      spree_post :index
      response.should render_template :index
    end

    it "allows admins to update a user's API key" do
      user.spree_roles << Spree::Role.find_or_create_by_name('admin')
      test_user.should_receive(:generate_spree_api_key!).and_return(true)
      puts user.id
      puts test_user.id
      spree_put :generate_api_key, id: test_user.id
      response.should redirect_to(spree.edit_admin_user_path(test_user))
    end

    it "allows admins to clear a user's API key" do
      user.spree_roles << Spree::Role.find_or_create_by_name('admin')
      test_user.should_receive(:clear_spree_api_key!).and_return(true)
      spree_put :clear_api_key, id: test_user.id
      response.should redirect_to(spree.edit_admin_user_path(test_user))
    end

    it 'should deny access to users with an bar role' do
      user.spree_roles << Spree::Role.find_or_create_by_name('bar')
      Spree::Ability.register_ability(BarAbility)
      spree_post :index
      response.should redirect_to('/unauthorized')
    end

    it 'should deny access to users with an bar role' do
      user.spree_roles << Spree::Role.find_or_create_by_name('bar')
      Spree::Ability.register_ability(BarAbility)
      spree_post :update, id: '9'
      response.should redirect_to('/unauthorized')
    end

    it 'should deny access to users without an admin role' do
      user.stub has_spree_role?: false
      spree_post :index
      response.should redirect_to('/unauthorized')
    end
  end
end
