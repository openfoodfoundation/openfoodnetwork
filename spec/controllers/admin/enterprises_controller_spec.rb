require 'spec_helper'
require 'open_food_network/order_cycle_permissions'

module Admin
  describe EnterprisesController do
    include AuthenticationWorkflow

    let(:user) { create(:user) }
    let(:admin_user) { create(:admin_user) }
    let(:distributor_manager) { create(:user, enterprise_limit: 10, enterprises: [distributor]) }
    let(:supplier_manager) { create(:user, enterprise_limit: 10, enterprises: [supplier]) }
    let(:distributor_owner) { create(:user, enterprise_limit: 10) }
    let(:supplier_owner) { create(:user) }

    let(:distributor) { create(:distributor_enterprise, owner: distributor_owner ) }
    let(:supplier) { create(:supplier_enterprise, owner: supplier_owner) }

    before { @request.env['HTTP_REFERER'] = 'http://test.com/' }

    describe "creating an enterprise" do
      let(:country) { Spree::Country.find_by_name 'Australia' }
      let(:state) { Spree::State.find_by_name 'Victoria' }
      let(:enterprise_params) { {enterprise: {name: 'zzz', permalink: 'zzz', is_primary_producer: '0', email: "bob@example.com", address_attributes: {address1: 'a', city: 'a', zipcode: 'a', country_id: country.id, state_id: state.id}}} }

      it "grants management permission if the current user is an enterprise user" do
        controller.stub spree_current_user: distributor_manager
        enterprise_params[:enterprise][:owner_id] = distributor_manager

        spree_put :create, enterprise_params
        enterprise = Enterprise.find_by_name 'zzz'
        response.should redirect_to edit_admin_enterprise_path enterprise
        distributor_manager.enterprise_roles.where(enterprise_id: enterprise).first.should be
      end

      it "does not grant management permission to admins" do
        controller.stub spree_current_user: admin_user
        enterprise_params[:enterprise][:owner_id] = admin_user

        spree_put :create, enterprise_params
        enterprise = Enterprise.find_by_name 'zzz'
        response.should redirect_to edit_admin_enterprise_path enterprise
        admin_user.enterprise_roles.where(enterprise_id: enterprise).should be_empty
      end

      it "overrides the owner_id submitted by the user (when not super admin)" do
        controller.stub spree_current_user: distributor_manager
        enterprise_params[:enterprise][:owner_id] = user

        spree_put :create, enterprise_params
        enterprise = Enterprise.find_by_name 'zzz'
        response.should redirect_to edit_admin_enterprise_path enterprise
        distributor_manager.enterprise_roles.where(enterprise_id: enterprise).first.should be
      end

      context "when I already own a hub" do
        before { distributor }

        it "creates new non-producers as hubs" do
          controller.stub spree_current_user: distributor_owner
          enterprise_params[:enterprise][:owner_id] = distributor_owner

          spree_put :create, enterprise_params
          enterprise = Enterprise.find_by_name 'zzz'
          response.should redirect_to edit_admin_enterprise_path enterprise
          enterprise.sells.should == 'any'
        end

        it "creates new producers as sells none" do
          controller.stub spree_current_user: distributor_owner
          enterprise_params[:enterprise][:owner_id] = distributor_owner
          enterprise_params[:enterprise][:is_primary_producer] = '1'

          spree_put :create, enterprise_params
          enterprise = Enterprise.find_by_name 'zzz'
          response.should redirect_to edit_admin_enterprise_path enterprise
          enterprise.sells.should == 'none'
        end

        it "doesn't affect the hub status for super admins" do
          admin_user.enterprises << create(:distributor_enterprise)

          controller.stub spree_current_user: admin_user
          enterprise_params[:enterprise][:owner_id] = admin_user
          enterprise_params[:enterprise][:sells] = 'none'

          spree_put :create, enterprise_params
          enterprise = Enterprise.find_by_name 'zzz'
          response.should redirect_to edit_admin_enterprise_path enterprise
          enterprise.sells.should == 'none'
        end
      end

      context "when I do not have a hub" do
        it "does not create the new enterprise as a hub" do
          controller.stub spree_current_user: supplier_manager
          enterprise_params[:enterprise][:owner_id] = supplier_manager

          spree_put :create, enterprise_params
          enterprise = Enterprise.find_by_name 'zzz'
          enterprise.sells.should == 'none'
        end

        it "doesn't affect the hub status for super admins" do
          controller.stub spree_current_user: admin_user
          enterprise_params[:enterprise][:owner_id] = admin_user
          enterprise_params[:enterprise][:sells] = 'any'

          spree_put :create, enterprise_params
          enterprise = Enterprise.find_by_name 'zzz'
          enterprise.sells.should == 'any'
        end
      end
    end

    describe "updating an enterprise" do
      let(:profile_enterprise) { create(:enterprise, sells: 'none') }

      context "as manager" do
        it "does not allow 'sells' to be changed" do
          profile_enterprise.enterprise_roles.build(user: distributor_manager).save
          controller.stub spree_current_user: distributor_manager
          enterprise_params = { id: profile_enterprise, enterprise: { sells: 'any' } }

          spree_put :update, enterprise_params
          profile_enterprise.reload
          expect(profile_enterprise.sells).to eq 'none'
        end

        it "does not allow owner to be changed" do
          controller.stub spree_current_user: distributor_manager
          update_params = { id: distributor, enterprise: { owner_id: distributor_manager } }
          spree_post :update, update_params

          distributor.reload
          expect(distributor.owner).to eq distributor_owner
        end

        it "does not allow managers to be changed" do
          controller.stub spree_current_user: distributor_manager
          update_params = { id: distributor, enterprise: { user_ids: [distributor_owner.id,distributor_manager.id,user.id] } }
          spree_post :update, update_params

          distributor.reload
          expect(distributor.users).to_not include user
        end

        describe "stripe connect" do
          it "redirects to Stripe" do
            controller.stub spree_current_user: distributor_manager
            spree_get :stripe_connect
            ['https://connect.stripe.com/oauth/authorize',
              'response_type=code',
              'state=',
              'client_id='].each{|element| response.location.should match element}
          end

          it "returns 500 on callback if the response code is not provided" do
            controller.stub spree_current_user: distributor_manager
            spree_get :stripe_connect_callback
            response.status.should be 500
          end

          it "redirects to login with the query params in case of session problems" do
            controller.stub spree_current_user: nil
            params = {this: "that"}
            spree_get :stripe_connect_callback, params
            # This is the correct redirect - but not sure it actually works since the redirect
            # is ultimately handled in Angular, which presumably doesn't know which controller to
            # use for the action
            response.should redirect_to root_path(anchor: "login?after_login=/?action=stripe_connect&this=that")
          end

          it "redirects to unauthorized if the callback state param is invalid" do
             controller.stub spree_current_user: distributor_manager
             payload = {junk: "Ssfs"}
             params = {state: JWT.encode(payload, Openfoodnetwork::Application.config.secret_token),
                        code: "code"}
             spree_get :stripe_connect_callback, params
             response.should redirect_to '/unauthorized'
          end

          # TODO: This should probably also include managers/coordinators as well as owners?
          it "makes a request to cancel the Stripe connection if the user does not own the enterprise" do
            controller.stub spree_current_user: distributor_manager
            controller.stub(:deauthorize_request_for_stripe_id)
            controller.stub_chain(:get_stripe_token, :params).and_return({stripe_user_id: "xyz123", stripe_publishable_key: "abc456"}.to_json)
            payload = {enterprise_id: supplier.permalink} # Request is not for the current user's Enterprise
            params = {state: JWT.encode(payload, Openfoodnetwork::Application.config.secret_token),
                        code: "code"}
            spree_get :stripe_connect_callback, params

            controller.should have_received(:deauthorize_request_for_stripe_id)
          end

          it "makes a new Stripe Account from the callback params" do
            controller.stub spree_current_user: distributor_manager
            controller.stub_chain(:get_stripe_token, :params).and_return({stripe_user_id: "xyz123", stripe_publishable_key: "abc456"}.to_json)
            payload = {enterprise_id: distributor.permalink}
            params = {state: JWT.encode(payload, Openfoodnetwork::Application.config.secret_token),
                        code: "code"}

            expect{spree_get :stripe_connect_callback, params}.to change{StripeAccount.all.length}.by 1
            StripeAccount.last.enterprise_id.should eq distributor.id
          end

        end


        describe "enterprise properties" do
          let(:producer) { create(:enterprise) }
          let!(:property) { create(:property, name: "A nice name") }

          before do
            login_as_enterprise_user [producer]
          end

          context "when a submitted property does not already exist" do
            it "does not create a new property, or product property" do
              spree_put :update, {
                id: producer,
                enterprise: {
                  producer_properties_attributes: {
                    '0' => { property_name: 'a different name', value: 'something' }
                  }
                }
              }
              expect(Spree::Property.count).to be 1
              expect(ProducerProperty.count).to be 0
              property_names = producer.reload.properties.map(&:name)
              expect(property_names).to_not include 'a different name'
            end
          end

          context "when a submitted property exists" do
            it "adds a product property" do
              spree_put :update, {
                id: producer,
                enterprise: {
                  producer_properties_attributes: {
                    '0' => { property_name: 'A nice name', value: 'something' }
                  }
                }
              }
              expect(Spree::Property.count).to be 1
              expect(ProducerProperty.count).to be 1
              property_names = producer.reload.properties.map(&:name)
              expect(property_names).to include 'A nice name'
            end
          end
        end

        describe "tag rules" do
          let(:enterprise) { create(:distributor_enterprise) }
          let!(:tag_rule) { create(:tag_rule, enterprise: enterprise) }

          before do
            login_as_enterprise_user [enterprise]
          end

          context "discount order rules" do
            it "updates the existing rule with new attributes" do
              spree_put :update, {
                id: enterprise,
                enterprise: {
                  tag_rules_attributes: {
                    '0' => {
                      id: tag_rule,
                      type: "TagRule::DiscountOrder",
                      preferred_customer_tags: "some,new,tags",
                      calculator_type: "Spree::Calculator::FlatPercentItemTotal",
                      calculator_attributes: { id: tag_rule.calculator.id, preferred_flat_percent: "15" }
                    }
                  }
                }
              }
              tag_rule.reload
              expect(tag_rule.preferred_customer_tags).to eq "some,new,tags"
              expect(tag_rule.calculator.preferred_flat_percent).to eq 15
            end

            it "creates new rules with new attributes" do
              spree_put :update, {
                id: enterprise,
                enterprise: {
                  tag_rules_attributes: {
                    '0' => {
                      id: "",
                      type: "TagRule::DiscountOrder",
                      preferred_customer_tags: "tags,are,awesome",
                      calculator_type: "Spree::Calculator::FlatPercentItemTotal",
                      calculator_attributes: { id: "", preferred_flat_percent: "24" }
                    }
                  }
                }
              }
              expect(tag_rule.reload).to be
              new_tag_rule = TagRule::DiscountOrder.last
              expect(new_tag_rule.preferred_customer_tags).to eq "tags,are,awesome"
              expect(new_tag_rule.calculator.preferred_flat_percent).to eq 24
            end
          end
        end
      end

      context "as owner" do
        it "allows 'sells' to be changed" do
          controller.stub spree_current_user: profile_enterprise.owner
          enterprise_params = { id: profile_enterprise, enterprise: { sells: 'any' } }

          spree_put :update, enterprise_params
          profile_enterprise.reload
          expect(profile_enterprise.sells).to eq 'any'
        end

        it "allows owner to be changed" do
          controller.stub spree_current_user: distributor_owner
          update_params = { id: distributor, enterprise: { owner_id: distributor_manager } }
          spree_post :update, update_params

          distributor.reload
          expect(distributor.owner).to eq distributor_manager
        end

        it "allows managers to be changed" do
          controller.stub spree_current_user: distributor_owner
          update_params = { id: distributor, enterprise: { user_ids: [distributor_owner.id,distributor_manager.id,user.id] } }
          spree_post :update, update_params

          distributor.reload
          expect(distributor.users).to include user
        end
      end

      context "as super admin" do
        it "allows 'sells' to be changed" do
          controller.stub spree_current_user: admin_user
          enterprise_params = { id: profile_enterprise, enterprise: { sells: 'any' } }

          spree_put :update, enterprise_params
          profile_enterprise.reload
          expect(profile_enterprise.sells).to eq 'any'
        end


        it "allows owner to be changed" do
          controller.stub spree_current_user: admin_user
          update_params = { id: distributor, enterprise: { owner_id: distributor_manager } }
          spree_post :update, update_params

          distributor.reload
          expect(distributor.owner).to eq distributor_manager
        end

        it "allows managers to be changed" do
          controller.stub spree_current_user: admin_user
          update_params = { id: distributor, enterprise: { user_ids: [distributor_owner.id,distributor_manager.id,user.id] } }
          spree_post :update, update_params

          distributor.reload
          expect(distributor.users).to include user
        end
      end
    end

    describe "register" do
      let(:enterprise) { create(:enterprise, sells: 'none') }

      context "as a normal user" do
        before do
          controller.stub spree_current_user: distributor_manager
        end

        it "does not allow access" do
          spree_post :register, { id: enterprise.id, sells: 'none' }
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "as a manager" do
        before do
          controller.stub spree_current_user: distributor_manager
          enterprise.enterprise_roles.build(user: distributor_manager).save
        end

        it "does not allow access" do
          spree_post :register, { id: enterprise.id, sells: 'none' }
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "as an owner" do
        before do
          controller.stub spree_current_user: enterprise.owner
        end

        context "setting 'sells' to 'none'" do
          it "is allowed" do
            spree_post :register, { id: enterprise, sells: 'none' }
            expect(response).to redirect_to spree.admin_path
            expect(flash[:success]).to eq "Congratulations! Registration for #{enterprise.name} is complete!"
            expect(enterprise.reload.sells).to eq 'none'
          end
        end

        context "setting producer_profile_only" do
          it "is ignored" do
            spree_post :register, { id: enterprise, sells: 'none', producer_profile_only: true }
            expect(response).to redirect_to spree.admin_path
            expect(enterprise.reload.producer_profile_only).to be false
          end
        end

        context "setting 'sells' to 'own'" do
          before do
            enterprise.sells = 'none'
            enterprise.save!
          end

          context "if the trial has finished" do
            let(:trial_start) { 30.days.ago.beginning_of_day }

            before do
              enterprise.update_attribute(:shop_trial_start_date, trial_start)
            end

            it "is allowed" do
              Timecop.freeze(Time.zone.local(2015, 4, 16, 14, 0, 0)) do
                spree_post :register, { id: enterprise, sells: 'own' }
                expect(response).to redirect_to spree.admin_path
                expect(enterprise.reload.sells).to eq 'own'
                expect(enterprise.shop_trial_start_date).to eq trial_start
              end
            end
          end

          context "if the trial has not finished" do
            let(:trial_start) { Date.current.to_time }

            before do
              enterprise.update_attribute(:shop_trial_start_date, trial_start)
            end

            it "is allowed, but trial start date is not reset" do
              spree_post :register, { id: enterprise, sells: 'own' }
              expect(response).to redirect_to spree.admin_path
              expect(enterprise.reload.sells).to eq 'own'
              expect(enterprise.shop_trial_start_date).to eq trial_start
            end
          end

          context "if a trial has not started" do
            it "is allowed" do
              spree_post :register, { id: enterprise, sells: 'own' }
              expect(response).to redirect_to spree.admin_path
              expect(flash[:success]).to eq "Congratulations! Registration for #{enterprise.name} is complete!"
              expect(enterprise.reload.sells).to eq 'own'
              expect(enterprise.reload.shop_trial_start_date).to be > Time.zone.now-(1.minute)
            end
          end
        end

        context "setting 'sells' to any" do
          context "if the trial has finished" do
            let(:trial_start) { 30.days.ago.beginning_of_day }

            before do
              enterprise.update_attribute(:shop_trial_start_date, trial_start)
            end

            it "is allowed" do
              Timecop.freeze(Time.zone.local(2015, 4, 16, 14, 0, 0)) do
                spree_post :register, { id: enterprise, sells: 'any' }
                expect(response).to redirect_to spree.admin_path
                expect(enterprise.reload.sells).to eq 'any'
                expect(enterprise.shop_trial_start_date).to eq trial_start
              end
            end
          end

          context "if the trial has not finished" do
            let(:trial_start) { Date.current.to_time }

            before do
              enterprise.update_attribute(:shop_trial_start_date, trial_start)
            end

            it "is allowed, but trial start date is not reset" do
              spree_post :register, { id: enterprise, sells: 'any' }
              expect(response).to redirect_to spree.admin_path
              expect(enterprise.reload.sells).to eq 'any'
              expect(enterprise.shop_trial_start_date).to eq trial_start
            end
          end

          context "if a trial has not started" do
            it "is allowed" do
              spree_post :register, { id: enterprise, sells: 'any' }
              expect(response).to redirect_to spree.admin_path
              expect(flash[:success]).to eq "Congratulations! Registration for #{enterprise.name} is complete!"
              expect(enterprise.reload.sells).to eq 'any'
              expect(enterprise.reload.shop_trial_start_date).to be > Time.zone.now-(1.minute)
            end
          end
        end

        context "settiing 'sells' to 'unspecified'" do
          it "is not allowed" do
            spree_post :register, { id: enterprise, sells: 'unspecified' }
            expect(response).to render_template :welcome
            expect(flash[:error]).to eq "Please select a package"
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

      context "as the owner of an enterprise" do
        it "allows 'sells' and 'owner' to be changed" do
          controller.stub spree_current_user: original_owner
          bulk_enterprise_params = { enterprise_set: { collection_attributes: { '0' => { id: profile_enterprise1.id, sells: 'any', owner_id: new_owner.id }, '1' => { id: profile_enterprise2.id, sells: 'any', owner_id: new_owner.id } } } }

          spree_put :bulk_update, bulk_enterprise_params
          profile_enterprise1.reload
          profile_enterprise2.reload
          expect(profile_enterprise1.sells).to eq 'any'
          expect(profile_enterprise2.sells).to eq 'any'
          expect(profile_enterprise1.owner).to eq original_owner
          expect(profile_enterprise2.owner).to eq original_owner
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

    describe "for_order_cycle" do
      let!(:user) { create_enterprise_user }
      let!(:enterprise) { create(:enterprise, sells: 'any', owner: user) }
      let(:permission_mock) { double(:permission) }

      before do
        # As a user with permission
        controller.stub spree_current_user: user
        OrderCycle.stub find_by_id: "existing OrderCycle"
        Enterprise.stub find_by_id: "existing Enterprise"
        OrderCycle.stub new: "new OrderCycle"

        allow(OpenFoodNetwork::OrderCyclePermissions).to receive(:new) { permission_mock }
        allow(permission_mock).to receive(:visible_enterprises) { [] }
        allow(ActiveModel::ArraySerializer).to receive(:new) { "" }
      end

      context "when no order_cycle or coordinator is provided in params" do
        before { spree_get :for_order_cycle, format: :json }
        it "initializes permissions with nil" do
          expect(OpenFoodNetwork::OrderCyclePermissions).to have_received(:new).with(user, nil)
        end
      end

      context "when an order_cycle_id is provided in params" do
        before { spree_get :for_order_cycle, format: :json, order_cycle_id: 1 }
        it "initializes permissions with the existing OrderCycle" do
          expect(OpenFoodNetwork::OrderCyclePermissions).to have_received(:new).with(user, "existing OrderCycle")
        end
      end

      context "when a coordinator is provided in params" do
        before { spree_get :for_order_cycle, format: :json, coordinator_id: 1 }
        it "initializes permissions with a new OrderCycle" do
          expect(OpenFoodNetwork::OrderCyclePermissions).to have_received(:new).with(user, "new OrderCycle")
        end
      end

      context "when both an order cycle and a coordinator are provided in params" do
        before { spree_get :for_order_cycle, format: :json, order_cycle_id: 1, coordinator_id: 1 }
        it "initializes permissions with the existing OrderCycle" do
          expect(OpenFoodNetwork::OrderCyclePermissions).to have_received(:new).with(user, "existing OrderCycle")
        end
      end
    end

    describe "for_line_items" do
      let!(:user) { create(:user) }
      let!(:enterprise) { create(:enterprise, sells: 'any', owner: user) }

      before do
        # As a user with permission
        controller.stub spree_current_user: user
      end

      it "initializes permissions with the existing OrderCycle" do
        # expect(controller).to receive(:render_as_json).with([enterprise], {ams_prefix: 'basic', spree_current_user: user})
        spree_get :for_line_items, format: :json
      end
    end

    describe "index" do
      context "as super admin" do
        let(:super_admin) { create(:admin_user) }
        let!(:user) { create_enterprise_user(enterprise_limit: 10) }
        let!(:enterprise1) { create(:enterprise, sells: 'any', owner: user) }
        let!(:enterprise2) { create(:enterprise, sells: 'own', owner: user) }
        let!(:enterprise3) { create(:enterprise, sells: 'any', owner: create_enterprise_user ) }

        before do
          controller.stub spree_current_user: super_admin
        end

        context "html" do
          it "returns all enterprises" do
            spree_get :index, format: :html
            expect(assigns(:collection)).to include enterprise1, enterprise2, enterprise3
          end
        end

        context "json" do
          it "returns all enterprises" do
            spree_get :index, format: :json
            expect(assigns(:collection)).to include enterprise1, enterprise2, enterprise3
          end
        end
      end

      context "as an enterprise user" do
        let!(:user) { create_enterprise_user(enterprise_limit: 10) }
        let!(:enterprise1) { create(:enterprise, sells: 'any', owner: user) }
        let!(:enterprise2) { create(:enterprise, sells: 'own', owner: user) }
        let!(:enterprise3) { create(:enterprise, sells: 'any', owner: create_enterprise_user ) }

        before do
          controller.stub spree_current_user: user
        end

        context "html" do
          it "returns an empty @collection" do
            spree_get :index, format: :html
            expect(assigns(:collection)).to eq []
          end
        end

        context "json" do
          it "scopes @collection to enterprises editable by the user" do
            spree_get :index, format: :json
            expect(assigns(:collection)).to include enterprise1, enterprise2
            expect(assigns(:collection)).to_not include enterprise3
          end
        end
      end
    end
  end
end
