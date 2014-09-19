require 'spec_helper'

module Admin
  describe EnterprisesController do
    include AuthenticationWorkflow
    let(:distributor_owner) do
      user = create(:user)
      user.spree_roles = []
      user
    end
    let(:distributor) { create(:distributor_enterprise, owner: distributor_owner ) }
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
        enterprise_params[:enterprise][:owner_id] = user

        spree_put :create, enterprise_params
        enterprise = Enterprise.find_by_name 'zzz'
        user.enterprise_roles.where(enterprise_id: enterprise).first.should be
      end

      it "does not grant management permission to admins" do
        controller.stub spree_current_user: admin_user
        enterprise_params[:enterprise][:owner_id] = admin_user

        spree_put :create, enterprise_params
        enterprise = Enterprise.find_by_name 'zzz'
        admin_user.enterprise_roles.where(enterprise_id: enterprise).should be_empty
      end

      it "it overrides the owner_id submitted by the user unless current_user is super admin" do
        controller.stub spree_current_user: user
        enterprise_params[:enterprise][:owner_id] = admin_user

        spree_put :create, enterprise_params
        enterprise = Enterprise.find_by_name 'zzz'
        user.enterprise_roles.where(enterprise_id: enterprise).first.should be
      end
    end

    describe "updating an enterprise" do
      it "allows current owner to change ownership" do
        controller.stub spree_current_user: distributor_owner
        update_params = { id: distributor, enterprise: { owner_id: user } }
        spree_post :update, update_params

        distributor.reload
        expect(distributor.owner).to eq user
      end

      it "allows super admin to change ownership" do
        controller.stub spree_current_user: admin_user
        update_params = { id: distributor, enterprise: { owner_id: user } }
        spree_post :update, update_params

        distributor.reload
        expect(distributor.owner).to eq user
      end

      it "does not allow managers to change ownership" do
        controller.stub spree_current_user: user
        update_params = { id: distributor, enterprise: { owner_id: user } }
        spree_post :update, update_params

        distributor.reload
        expect(distributor.owner).to eq distributor_owner
      end
    end

    describe "updating an enterprise" do
      let(:profile_enterprise) { create(:enterprise, type: 'profile') }

      context "as manager" do
        it "does not allow 'type' to be changed" do
          profile_enterprise.enterprise_roles.build(user: user).save
          controller.stub spree_current_user: user
          enterprise_params = { id: profile_enterprise.id, enterprise: { type: 'full' } }

          spree_put :update, enterprise_params
          profile_enterprise.reload
          expect(profile_enterprise.type).to eq 'profile'
        end
      end

      context "as super admin" do
        it "allows 'type' to be changed" do
          controller.stub spree_current_user: admin_user
          enterprise_params = { id: profile_enterprise.id, enterprise: { type: 'full' } }

          spree_put :update, enterprise_params
          profile_enterprise.reload
          expect(profile_enterprise.type).to eq 'full'
        end
      end
    end

    describe "bulk updating enterprises" do
      let!(:original_owner) do
        user = create_enterprise_user
        user.enterprise_limit = 2
        user.save!
        user
      end
      let!(:new_owner) do
        user = create_enterprise_user
        user.enterprise_limit = 2
        user.save!
        user
      end
      let!(:profile_enterprise1) { create(:enterprise, type: 'profile', owner: original_owner ) }
      let!(:profile_enterprise2) { create(:enterprise, type: 'profile', owner: original_owner ) }

      context "as manager" do
        it "does not allow 'type' or 'owner' to be changed" do
          profile_enterprise1.enterprise_roles.build(user: new_owner).save
          profile_enterprise2.enterprise_roles.build(user: new_owner).save
          controller.stub spree_current_user: new_owner
          bulk_enterprise_params = { enterprise_set: { collection_attributes: { '0' => { id: profile_enterprise1.id, type: 'full', owner_id: new_owner.id }, '1' => { id: profile_enterprise2.id, type: 'full', owner_id: new_owner.id } } } }

          spree_put :bulk_update, bulk_enterprise_params
          profile_enterprise1.reload
          profile_enterprise2.reload
          expect(profile_enterprise1.type).to eq 'profile'
          expect(profile_enterprise2.type).to eq 'profile'
          expect(profile_enterprise1.owner).to eq original_owner
          expect(profile_enterprise2.owner).to eq original_owner
        end
      end

      context "as super admin" do
        it "allows 'type' and 'owner' to be changed" do
          profile_enterprise1.enterprise_roles.build(user: new_owner).save
          profile_enterprise2.enterprise_roles.build(user: new_owner).save
          controller.stub spree_current_user: admin_user
          bulk_enterprise_params = { enterprise_set: { collection_attributes: { '0' => { id: profile_enterprise1.id, type: 'full', owner_id: new_owner.id }, '1' => { id: profile_enterprise2.id, type: 'full', owner_id: new_owner.id } } } }

          spree_put :bulk_update, bulk_enterprise_params
          profile_enterprise1.reload
          profile_enterprise2.reload
          expect(profile_enterprise1.type).to eq 'full'
          expect(profile_enterprise2.type).to eq 'full'
          expect(profile_enterprise1.owner).to eq new_owner
          expect(profile_enterprise2.owner).to eq new_owner
        end
      end
    end
  end
end
