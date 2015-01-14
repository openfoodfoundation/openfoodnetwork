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
      let(:enterprise_params) { {enterprise: {name: 'zzz', email: "bob@example.com", address_attributes: {address1: 'a', city: 'a', zipcode: 'a', country_id: country.id, state_id: state.id}}} }

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
      let(:profile_enterprise) { create(:enterprise, sells: 'none') }

      context "as manager" do
        it "does not allow 'sells' to be changed" do
          profile_enterprise.enterprise_roles.build(user: user).save
          controller.stub spree_current_user: user
          enterprise_params = { id: profile_enterprise.id, enterprise: { sells: 'any' } }

          spree_put :update, enterprise_params
          profile_enterprise.reload
          expect(profile_enterprise.sells).to eq 'none'
        end
      end

      context "as super admin" do
        it "allows 'sells' to be changed" do
          controller.stub spree_current_user: admin_user
          enterprise_params = { id: profile_enterprise.id, enterprise: { sells: 'any' } }

          spree_put :update, enterprise_params
          profile_enterprise.reload
          expect(profile_enterprise.sells).to eq 'any'
        end
      end
    end

    describe "set_sells" do
      let(:enterprise) { create(:enterprise, sells: 'none') }

      before do
        controller.stub spree_current_user: user
      end

      context "as a normal user" do
        it "does not allow 'sells' to be set" do
          spree_post :set_sells, { id: enterprise.id, sells: 'none' }
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "as a manager" do
        before do
          enterprise.enterprise_roles.build(user: user).save
        end

        context "allows setting 'sells' to 'none'" do
          it "is allowed" do
            spree_post :set_sells, { id: enterprise.id, sells: 'none' }
            expect(response).to redirect_to spree.admin_path
            expect(flash[:success]).to eq "Congratulations! Registration for #{enterprise.name} is complete!"
            expect(enterprise.reload.sells).to eq 'none'
          end

          context "setting producer_profile_only to true" do
            it "is allowed" do
              spree_post :set_sells, { id: enterprise.id, sells: 'none', producer_profile_only: true }
              expect(response).to redirect_to spree.admin_path
              expect(enterprise.reload.producer_profile_only).to eq true
            end
          end
        end

        context "setting 'sells' to 'own'" do
          before do
            enterprise.sells = 'own'
            enterprise.save!
          end

          context "if the trial has finished" do
            before do
              enterprise.shop_trial_start_date = (Date.today - 30.days).to_time
              enterprise.save!
            end

            it "is disallowed" do
              spree_post :set_sells, { id: enterprise.id, sells: 'own' }
              expect(response).to redirect_to spree.admin_path
              trial_expiry = Date.today.strftime("%Y-%m-%d")
              expect(flash[:error]).to eq "Sorry, but you've already had a trial. Expired on: #{trial_expiry}"
              expect(enterprise.reload.sells).to eq 'own'
              expect(enterprise.reload.shop_trial_start_date).to eq (Date.today - 30.days).to_time
            end
          end

          context "if the trial has not finished" do
            before do
              enterprise.shop_trial_start_date = Date.today.to_time
              enterprise.save!
            end

            it "is allowed, but trial start date is not reset" do
              spree_post :set_sells, { id: enterprise.id, sells: 'own' }
              expect(response).to redirect_to spree.admin_path
              trial_expiry = (Date.today + 30.days).strftime("%Y-%m-%d")
              expect(flash[:notice]).to eq "Welcome back! Your trial expires on: #{trial_expiry}"
              expect(enterprise.reload.sells).to eq 'own'
              expect(enterprise.reload.shop_trial_start_date).to eq Date.today.to_time
            end
          end

          context "if a trial has not started" do
            it "is allowed" do
              spree_post :set_sells, { id: enterprise.id, sells: 'own' }
              expect(response).to redirect_to spree.admin_path
              expect(flash[:success]).to eq "Congratulations! Registration for #{enterprise.name} is complete!"
              expect(enterprise.reload.sells).to eq 'own'
              expect(enterprise.reload.shop_trial_start_date).to be > Time.now-(1.minute)
            end
          end

          context "setting producer_profile_only to true" do
            it "is ignored" do
              spree_post :set_sells, { id: enterprise.id, sells: 'own', producer_profile_only: true }
              expect(response).to redirect_to spree.admin_path
              expect(enterprise.reload.producer_profile_only).to be false
            end
          end
        end

        context "setting 'sells' to any" do
          it "is not allowed" do
            spree_post :set_sells, { id: enterprise.id, sells: 'any' }
            expect(response).to redirect_to spree.admin_path
            expect(flash[:error]).to eq "Unauthorised"
            expect(enterprise.reload.sells).to eq 'none'
          end
        end

        context "settiing 'sells' to 'unspecified'" do
          it "is not allowed" do
            spree_post :set_sells, { id: enterprise.id, sells: 'unspecified' }
            expect(response).to redirect_to spree.admin_path
            expect(flash[:error]).to eq "Unauthorised"
            expect(enterprise.reload.sells).to eq 'none'
          end
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
      let!(:profile_enterprise1) { create(:enterprise, sells: 'none', owner: original_owner ) }
      let!(:profile_enterprise2) { create(:enterprise, sells: 'none', owner: original_owner ) }

      context "as manager" do
        it "does not allow 'sells' or 'owner' to be changed" do
          profile_enterprise1.enterprise_roles.build(user: new_owner).save
          profile_enterprise2.enterprise_roles.build(user: new_owner).save
          controller.stub spree_current_user: new_owner
          bulk_enterprise_params = { enterprise_set: { collection_attributes: { '0' => { id: profile_enterprise1.id, sells: 'any', owner_id: new_owner.id }, '1' => { id: profile_enterprise2.id, sells: 'any', owner_id: new_owner.id } } } }

          spree_put :bulk_update, bulk_enterprise_params
          profile_enterprise1.reload
          profile_enterprise2.reload
          expect(profile_enterprise1.sells).to eq 'none'
          expect(profile_enterprise2.sells).to eq 'none'
          expect(profile_enterprise1.owner).to eq original_owner
          expect(profile_enterprise2.owner).to eq original_owner
        end

        it "cuts down the list of enterprises displayed when error received on bulk update" do
          EnterpriseSet.any_instance.stub(:save) { false }
          profile_enterprise1.enterprise_roles.build(user: new_owner).save
          controller.stub spree_current_user: new_owner
          bulk_enterprise_params = { enterprise_set: { collection_attributes: { '0' => { id: profile_enterprise1.id, visible: 'false' } } } }
          spree_put :bulk_update, bulk_enterprise_params
          expect(assigns(:enterprise_set).collection).to eq [profile_enterprise1]
        end
      end

      context "as super admin" do
        it "allows 'sells' and 'owner' to be changed" do
          profile_enterprise1.enterprise_roles.build(user: new_owner).save
          profile_enterprise2.enterprise_roles.build(user: new_owner).save
          controller.stub spree_current_user: admin_user
          bulk_enterprise_params = { enterprise_set: { collection_attributes: { '0' => { id: profile_enterprise1.id, sells: 'any', owner_id: new_owner.id }, '1' => { id: profile_enterprise2.id, sells: 'any', owner_id: new_owner.id } } } }

          spree_put :bulk_update, bulk_enterprise_params
          profile_enterprise1.reload
          profile_enterprise2.reload
          expect(profile_enterprise1.sells).to eq 'any'
          expect(profile_enterprise2.sells).to eq 'any'
          expect(profile_enterprise1.owner).to eq new_owner
          expect(profile_enterprise2.owner).to eq new_owner
        end
      end
    end

    describe "checking permalink suitability" do
      # let(:enterprise) { create(:enterprise, permalink: 'enterprise_permalink') }

      before do
        controller.stub spree_current_user: admin_user
      end

      it "responds with status of 200 when the route does not exist" do
        spree_get :check_permalink, { permalink: 'some_nonexistent_route', format: :js }
        expect(response.status).to be 200
      end

      it "responds with status of 409 when the permalink matches an existing route" do
        # spree_get :check_permalink, { permalink: 'enterprise_permalink', format: :js }
        # expect(response.status).to be 409
        spree_get :check_permalink, { permalink: 'map', format: :js }
        expect(response.status).to be 409
        spree_get :check_permalink, { permalink: '', format: :js }
        expect(response.status).to be 409
      end
    end
  end
end
