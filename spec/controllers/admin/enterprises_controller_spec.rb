require 'spec_helper'

module Admin
  describe EnterprisesController do
    let(:distributor) { create(:distributor_enterprise) }
    let(:user) do
      user = create(:user)
      user.spree_roles = []
      distributor.enterprise_roles.build(user: user).save
      user
    end
    let(:admin_user) do
      user = create(:user)
      user.spree_roles << Spree::Role.find_or_create_by_name!('admin')
      user
    end

    describe "creating an enterprise" do
      let(:country) { Spree::Country.find_by_name 'Australia' }
      let(:state) { Spree::State.find_by_name 'Victoria' }
      let(:enterprise_params) { {enterprise: {name: 'zzz', address_attributes: {address1: 'a', city: 'a', zipcode: 'a', country_id: country.id, state_id: state.id}}} }

      it "grants management permission if the current user is an enterprise user" do
        controller.stub spree_current_user: user

        spree_put :create, enterprise_params
        enterprise = Enterprise.find_by_name 'zzz'
        user.enterprise_roles.where(enterprise_id: enterprise).first.should be
      end

      it "does not grant management permission to admins" do
        controller.stub spree_current_user: admin_user

        spree_put :create, enterprise_params
        enterprise = Enterprise.find_by_name 'zzz'
        admin_user.enterprise_roles.where(enterprise_id: enterprise).should be_empty
      end
    end
  end
end
