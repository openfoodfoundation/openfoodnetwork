# frozen_string_literal: false

require 'spec_helper'
require 'open_food_network/order_cycle_permissions'

describe Admin::EnterprisesController, type: :controller do
  let(:user) { create(:user) }
  let(:admin_user) { create(:admin_user) }
  let(:distributor_manager) { create(:user, enterprise_limit: 10, enterprises: [distributor]) }
  let(:supplier_manager) { create(:user, enterprise_limit: 10, enterprises: [supplier]) }
  let(:distributor_owner) { create(:user, enterprise_limit: 10) }
  let(:supplier_owner) { create(:user) }

  let(:distributor) { create(:distributor_enterprise, owner: distributor_owner ) }
  let(:supplier) { create(:supplier_enterprise, owner: supplier_owner) }
  let(:country) { Spree::Country.find_by name: 'Australia' }
  let(:state) { Spree::State.find_by name: 'Victoria' }
  let(:address_params) {
    { address1: 'a', city: 'a', zipcode: 'a', country_id: country.id, state_id: state.id }
  }

  before { @request.env['HTTP_REFERER'] = 'http://test.com/' }

  describe "creating an enterprise" do
    let(:enterprise_params) {
      { enterprise: { name: 'zzz', permalink: 'zzz', is_primary_producer: '0',
                      address_attributes: address_params } }
    }

    it "grants management permission if the current user is an enterprise user" do
      allow(controller).to receive_messages spree_current_user: distributor_manager
      enterprise_params[:enterprise][:owner_id] = distributor_manager

      spree_put :create, enterprise_params
      enterprise = Enterprise.find_by name: 'zzz'
      expect(response).to redirect_to edit_admin_enterprise_path enterprise
      expect(distributor_manager.enterprise_roles.where(enterprise_id: enterprise).first).to be
    end

    it "overrides the owner_id submitted by the user (when not super admin)" do
      allow(controller).to receive_messages spree_current_user: distributor_manager
      enterprise_params[:enterprise][:owner_id] = user

      spree_put :create, enterprise_params
      enterprise = Enterprise.find_by name: 'zzz'
      expect(response).to redirect_to edit_admin_enterprise_path enterprise
      expect(distributor_manager.enterprise_roles.where(enterprise_id: enterprise).first).to be
    end

    it "set the `visible` attribute to `hidden`" do
      allow(controller).to receive_messages spree_current_user: distributor_manager
      enterprise_params[:enterprise][:owner_id] = distributor_manager

      spree_put :create, enterprise_params
      enterprise = Enterprise.find_by name: 'zzz'
      expect(enterprise.visible).to eq 'only_through_links'
    end

    context "when I already own a hub" do
      before { distributor }

      it "creates new non-producers as hubs" do
        allow(controller).to receive_messages spree_current_user: distributor_owner
        enterprise_params[:enterprise][:owner_id] = distributor_owner

        spree_put :create, enterprise_params
        enterprise = Enterprise.find_by name: 'zzz'
        expect(response).to redirect_to edit_admin_enterprise_path enterprise
        expect(enterprise.sells).to eq('any')
      end

      it "creates new producers as sells none" do
        allow(controller).to receive_messages spree_current_user: distributor_owner
        enterprise_params[:enterprise][:owner_id] = distributor_owner
        enterprise_params[:enterprise][:is_primary_producer] = '1'

        spree_put :create, enterprise_params
        enterprise = Enterprise.find_by name: 'zzz'
        expect(response).to redirect_to edit_admin_enterprise_path enterprise
        expect(enterprise.sells).to eq('none')
      end

      it "doesn't affect the hub status for super admins" do
        admin_user.enterprises << create(:distributor_enterprise)

        allow(controller).to receive_messages spree_current_user: admin_user
        enterprise_params[:enterprise][:owner_id] = admin_user.id
        enterprise_params[:enterprise][:sells] = 'none'

        spree_put :create, enterprise_params
        enterprise = Enterprise.find_by name: 'zzz'
        expect(response).to redirect_to edit_admin_enterprise_path enterprise
        expect(enterprise.sells).to eq('none')
      end
    end

    context "when I do not have a hub" do
      it "does not create the new enterprise as a hub" do
        allow(controller).to receive_messages spree_current_user: supplier_manager
        enterprise_params[:enterprise][:owner_id] = supplier_manager

        spree_put :create, enterprise_params
        enterprise = Enterprise.find_by name: 'zzz'
        expect(enterprise.sells).to eq('none')
      end

      it "doesn't affect the hub status for super admins" do
        allow(controller).to receive_messages spree_current_user: admin_user
        enterprise_params[:enterprise][:owner_id] = admin_user.id
        enterprise_params[:enterprise][:sells] = 'any'

        spree_put :create, enterprise_params
        enterprise = Enterprise.find_by name: 'zzz'
        expect(enterprise.sells).to eq('any')
      end
    end

    context "geocoding" do
      before do
        allow(controller).to receive_messages spree_current_user: admin_user
        enterprise_params[:enterprise][:owner_id] = admin_user.id
      end

      it "geocodes the address when the :use_geocoder parameter is set" do
        expect_any_instance_of(AddressGeocoder).to receive(:geocode)
        enterprise_params[:use_geocoder] = "1"

        spree_put :create, enterprise_params
      end

      it "doesn't geocode the address when the :use_geocoder parameter is not set" do
        expect_any_instance_of(AddressGeocoder).not_to receive(:geocode)
        enterprise_params[:use_geocoder] = "0"

        spree_put :create, enterprise_params
      end
    end
  end

  describe "updating an enterprise" do
    let(:profile_enterprise) { create(:enterprise, sells: 'none') }

    context "as manager" do
      it "does not allow 'sells' to be changed" do
        profile_enterprise.enterprise_roles.build(user: distributor_manager).save
        allow(controller).to receive_messages spree_current_user: distributor_manager
        enterprise_params = { id: profile_enterprise, enterprise: { sells: 'any' } }

        spree_put :update, enterprise_params
        profile_enterprise.reload
        expect(profile_enterprise.sells).to eq 'none'
      end

      it "does not allow owner to be changed" do
        allow(controller).to receive_messages spree_current_user: distributor_manager
        update_params = { id: distributor, enterprise: { owner_id: distributor_manager } }
        spree_post :update, update_params

        distributor.reload
        expect(distributor.owner).to eq distributor_owner
      end

      it "does not allow managers to be changed" do
        allow(controller).to receive_messages spree_current_user: distributor_manager
        update_params = { id: distributor,
                          enterprise: { user_ids: [distributor_owner.id, distributor_manager.id,
                                                   user.id] } }
        spree_post :update, update_params

        distributor.reload
        expect(distributor.users).to_not include user
      end

      it "updates the contact for notifications" do
        allow(controller).to receive_messages spree_current_user: distributor_manager
        params = {
          id: distributor,
          receives_notifications: distributor_manager.id,
        }

        expect { spree_post :update, params }.
          to change { distributor.contact }.to(distributor_manager)
      end

      it "updates the contact for notifications" do
        allow(controller).to receive_messages spree_current_user: distributor_manager
        params = {
          id: distributor,
          receives_notifications: "? object:null ?",
        }

        expect { spree_post :update, params }.
          to_not change { distributor.contact }
      end

      it "updates enterprise preferences" do
        allow(controller).to receive_messages spree_current_user: distributor_manager
        update_params = { id: distributor,
                          enterprise: { show_customer_names_to_suppliers: "1" } }
        spree_post :update, update_params

        distributor.reload
        expect(distributor.show_customer_names_to_suppliers).to eq true
      end

      describe "enterprise properties" do
        let(:producer) { create(:enterprise) }
        let!(:property) { create(:property, name: "A nice name") }

        before do
          controller_login_as_enterprise_user [producer]
        end

        context "when a submitted property does not already exist" do
          it "does not create a new property, or product property" do
            spree_put :update,
                      id: producer,
                      enterprise: {
                        producer_properties_attributes: {
                          '0' => { property_name: 'a different name', value: 'something' }
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
            spree_put :update,
                      id: producer,
                      enterprise: {
                        producer_properties_attributes: {
                          '0' => { property_name: 'A nice name', value: 'something' }
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
        let!(:tag_rule) { create(:filter_order_cycles_tag_rule, enterprise: enterprise) }

        before do
          controller_login_as_enterprise_user [enterprise]
        end

        context "with filter_order_cycles rule" do
          it "updates the existing rule with new attributes" do
            spree_put :update,
                      id: enterprise,
                      enterprise: {
                        tag_rules_attributes: {
                          '0' => {
                            id: tag_rule.id,
                            type: "TagRule::FilterOrderCycles",
                            preferred_exchange_tags: "some,new,tags"
                          }
                        }
                      }
            tag_rule.reload
            expect(tag_rule.preferred_exchange_tags).to eq "some,new,tags"
          end

          it "creates new rules with new attributes" do
            spree_put :update,
                      id: enterprise,
                      enterprise: {
                        tag_rules_attributes: {
                          '0' => {
                            id: "",
                            type: "TagRule::FilterOrderCycles",
                            preferred_exchange_tags: "tags,are,awesome"
                          }
                        }
                      }
            expect(tag_rule.reload).to be
            new_tag_rule = TagRule::FilterOrderCycles.last
            expect(new_tag_rule.preferred_exchange_tags).to eq "tags,are,awesome"
          end
        end
      end
    end

    context "as owner" do
      it "allows 'sells' to be changed" do
        allow(controller).to receive_messages spree_current_user: profile_enterprise.owner
        enterprise_params = { id: profile_enterprise, enterprise: { sells: 'any' } }

        spree_put :update, enterprise_params
        profile_enterprise.reload
        expect(profile_enterprise.sells).to eq 'any'
      end

      it "allows owner to be changed" do
        allow(controller).to receive_messages spree_current_user: distributor_owner
        update_params = { id: distributor, enterprise: { owner_id: distributor_manager.id } }
        spree_post :update, update_params

        distributor.reload
        expect(distributor.owner).to eq distributor_manager
      end

      it "allows managers to be changed" do
        allow(controller).to receive_messages spree_current_user: distributor_owner
        update_params = { id: distributor,
                          enterprise: { user_ids: [distributor_owner.id, distributor_manager.id,
                                                   user.id] } }
        spree_post :update, update_params

        distributor.reload
        expect(distributor.users).to include user
      end
    end

    context "as super admin" do
      it "allows 'sells' to be changed" do
        allow(controller).to receive_messages spree_current_user: admin_user
        enterprise_params = { id: profile_enterprise, enterprise: { sells: 'any' } }

        spree_put :update, enterprise_params
        profile_enterprise.reload
        expect(profile_enterprise.sells).to eq 'any'
      end

      it "allows owner to be changed" do
        allow(controller).to receive_messages spree_current_user: admin_user
        update_params = { id: distributor, enterprise: { owner_id: distributor_manager.id } }
        spree_post :update, update_params

        distributor.reload
        expect(distributor.owner).to eq distributor_manager
      end

      it "allows managers to be changed" do
        allow(controller).to receive_messages spree_current_user: admin_user
        update_params = { id: distributor,
                          enterprise: { user_ids: [distributor_owner.id, distributor_manager.id,
                                                   user.id] } }
        spree_post :update, update_params

        distributor.reload
        expect(distributor.users).to include user
      end
    end

    context "geocoding" do
      before do
        allow(controller).to receive_messages spree_current_user: profile_enterprise.owner
      end

      it "geocodes the address when the :use_geocoder parameter is set" do
        expect_any_instance_of(AddressGeocoder).to receive(:geocode)
        enterprise_params = { id: profile_enterprise, enterprise: {}, use_geocoder: "1" }

        spree_put :update, enterprise_params
      end

      it "doesn't geocode the address when the :use_geocoder parameter is not set" do
        expect_any_instance_of(AddressGeocoder).not_to receive(:geocode)
        enterprise_params = { id: profile_enterprise, enterprise: {}, use_geocoder: "0" }

        spree_put :update, enterprise_params
      end
    end
  end

  describe "register" do
    let(:enterprise) { create(:enterprise, sells: 'none') }

    context "as a normal user" do
      before do
        allow(controller).to receive_messages spree_current_user: distributor_manager
      end

      it "does not allow access" do
        spree_post :register, id: enterprise.id, sells: 'none'
        expect(response).to redirect_to unauthorized_path
      end
    end

    context "as a manager" do
      before do
        allow(controller).to receive_messages spree_current_user: distributor_manager
        enterprise.enterprise_roles.build(user: distributor_manager).save
      end

      it "does not allow access" do
        spree_post :register, id: enterprise.id, sells: 'none'
        expect(response).to redirect_to unauthorized_path
      end
    end

    context "as an owner" do
      before do
        allow(controller).to receive_messages spree_current_user: enterprise.owner
      end

      context "setting 'sells' to 'none'" do
        it "is allowed" do
          spree_post :register, id: enterprise, sells: 'none'
          expect(response).to redirect_to spree.admin_dashboard_path
          expect(flash[:success])
            .to eq "Congratulations! Registration for #{enterprise.name} is complete!"
          expect(enterprise.reload.sells).to eq 'none'
        end
      end

      context "setting producer_profile_only" do
        it "is ignored" do
          spree_post :register, id: enterprise, sells: 'none', producer_profile_only: true
          expect(response).to redirect_to spree.admin_dashboard_path
          expect(enterprise.reload.producer_profile_only).to be false
        end
      end

      context "setting 'sells' to 'own'" do
        before do
          enterprise.sells = 'none'
          enterprise.save!
        end

        it "is allowed" do
          spree_post :register, id: enterprise, sells: 'own'
          expect(response).to redirect_to spree.admin_dashboard_path
          expect(flash[:success])
            .to eq "Congratulations! Registration for #{enterprise.name} is complete!"
          expect(enterprise.reload.sells).to eq 'own'
        end
      end

      context "setting 'sells' to any" do
        it "is allowed" do
          spree_post :register, id: enterprise, sells: 'any'
          expect(response).to redirect_to spree.admin_dashboard_path
          expect(flash[:success])
            .to eq "Congratulations! Registration for #{enterprise.name} is complete!"
          expect(enterprise.reload.sells).to eq 'any'
        end
      end

      context "settiing 'sells' to 'unspecified'" do
        it "is not allowed" do
          spree_post :register, id: enterprise, sells: 'unspecified'
          expect(response).to render_template :welcome
          expect(flash[:error]).to eq "Please select a package"
        end
      end

      it "set visibility to 'only_through_links' by default" do
        spree_post :register, id: enterprise, sells: 'none'
        expect(enterprise.reload.visible).to eq 'only_through_links'
      end
    end
  end

  describe "bulk updating enterprises" do
    let!(:original_owner) { create(:user) }
    let!(:new_owner) { create(:user) }
    let!(:profile_enterprise1) { create(:enterprise, sells: 'none', owner: original_owner ) }
    let!(:profile_enterprise2) { create(:enterprise, sells: 'none', owner: original_owner ) }

    context "as manager" do
      it "does not allow 'sells' or 'owner' to be changed" do
        profile_enterprise1.enterprise_roles.build(user: new_owner).save
        profile_enterprise2.enterprise_roles.build(user: new_owner).save
        allow(controller).to receive_messages spree_current_user: new_owner
        bulk_enterprise_params = { sets_enterprise_set: { collection_attributes: {
          '0' => { id: profile_enterprise1.id, sells: 'any',
                   owner_id: new_owner.id }, '1' => { id: profile_enterprise2.id,
                                                      sells: 'any',
                                                      owner_id: new_owner.id }
        } } }

        spree_put :bulk_update, bulk_enterprise_params
        profile_enterprise1.reload
        profile_enterprise2.reload
        expect(profile_enterprise1.sells).to eq 'none'
        expect(profile_enterprise2.sells).to eq 'none'
        expect(profile_enterprise1.owner).to eq original_owner
        expect(profile_enterprise2.owner).to eq original_owner
      end

      it "cuts down the list of enterprises displayed when error received on bulk update" do
        allow_any_instance_of(Sets::EnterpriseSet).to receive(:save) { false }
        profile_enterprise1.enterprise_roles.build(user: new_owner).save
        allow(controller).to receive_messages spree_current_user: new_owner
        bulk_enterprise_params = { sets_enterprise_set: { collection_attributes: { '0' => {
          id: profile_enterprise1.id, visible: 'false'
        } } } }
        spree_put :bulk_update, bulk_enterprise_params
        expect(assigns(:enterprise_set).collection).to eq [profile_enterprise1]
      end
    end

    context "as the owner of an enterprise" do
      it "allows 'sells' and 'owner' to be changed" do
        allow(controller).to receive_messages spree_current_user: original_owner
        bulk_enterprise_params = { sets_enterprise_set: { collection_attributes: {
          '0' => { id: profile_enterprise1.id, sells: 'any',
                   owner_id: new_owner.id }, '1' => { id: profile_enterprise2.id,
                                                      sells: 'any',
                                                      owner_id: new_owner.id }
        } } }

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
        allow(controller).to receive_messages spree_current_user: admin_user
        bulk_enterprise_params = { sets_enterprise_set: { collection_attributes: {
          '0' => { id: profile_enterprise1.id, sells: 'any',
                   owner_id: new_owner.id }, '1' => { id: profile_enterprise2.id,
                                                      sells: 'any',
                                                      owner_id: new_owner.id }
        } } }

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
    let!(:user) { create(:user) }
    let!(:enterprise) { create(:enterprise, sells: 'any', owner: user) }
    let(:permission_mock) { double(:permission) }

    before do
      # As a user with permission
      allow(controller).to receive_messages spree_current_user: user
      allow(OrderCycle).to receive_messages find_by: "existing OrderCycle"
      allow(Enterprise).to receive_messages find_by: "existing Enterprise"
      allow(OrderCycle).to receive_messages new: "new OrderCycle"

      allow(OpenFoodNetwork::OrderCyclePermissions).to receive(:new) { permission_mock }
      allow(permission_mock).to receive(:visible_enterprises) { [] }
      allow(ActiveModel::ArraySerializer).to receive(:new) { "" }
    end

    context "when no order_cycle or coordinator is provided in params" do
      before { get :for_order_cycle, format: :json }
      it "initializes permissions with nil" do
        expect(OpenFoodNetwork::OrderCyclePermissions).to have_received(:new).with(user, nil)
      end
    end

    context "when an order_cycle_id is provided in params" do
      before { get :for_order_cycle, as: :json, params: { order_cycle_id: 1 } }
      it "initializes permissions with the existing OrderCycle" do
        expect(OpenFoodNetwork::OrderCyclePermissions).to have_received(:new)
          .with(user, "existing OrderCycle")
      end
    end

    context "when a coordinator is provided in params" do
      before { get :for_order_cycle, as: :json, params: { coordinator_id: 1 } }
      it "initializes permissions with a new OrderCycle" do
        expect(OpenFoodNetwork::OrderCyclePermissions).to have_received(:new).with(user,
                                                                                   "new OrderCycle")
      end
    end

    context "when both an order cycle and a coordinator are provided in params" do
      before { get :for_order_cycle, as: :json, params: { order_cycle_id: 1, coordinator_id: 1 } }
      it "initializes permissions with the existing OrderCycle" do
        expect(OpenFoodNetwork::OrderCyclePermissions).to have_received(:new)
          .with(user, "existing OrderCycle")
      end
    end
  end

  describe "visible" do
    let!(:user) { create(:user) }
    let!(:visible_enterprise) { create(:enterprise, sells: 'any', owner: user) }
    let!(:not_visible_enterprise) { create(:enterprise, sells: 'any') }

    before do
      # As a user with permission
      allow(controller).to receive_messages spree_current_user: user

      # :create_variant_overrides does not affect visiblity (at time of writing)
      create(:enterprise_relationship, parent: not_visible_enterprise, child: visible_enterprise,
                                       permissions_list: [:create_variant_overrides])
    end

    it "uses permissions to determine which enterprises are visible and should be rendered" do
      expect(controller).to receive(:render_as_json)
        .with([visible_enterprise], ams_prefix: 'basic', spree_current_user: user).and_call_original
      get :visible, format: :json
    end
  end

  describe "index" do
    context "as super admin" do
      let(:super_admin) { create(:admin_user) }
      let!(:user) { create(:user) }
      let!(:enterprise1) { create(:enterprise, sells: 'any', owner: user) }
      let!(:enterprise2) { create(:enterprise, sells: 'own', owner: user) }
      let!(:enterprise3) { create(:enterprise, sells: 'any', owner: create(:user) ) }

      before do
        allow(controller).to receive_messages spree_current_user: super_admin
      end

      context "html" do
        it "returns all enterprises" do
          get :index, format: :html
          expect(assigns(:collection)).to include enterprise1, enterprise2, enterprise3
        end
      end

      context "json" do
        it "returns all enterprises" do
          get :index, format: :json
          expect(assigns(:collection)).to include enterprise1, enterprise2, enterprise3
        end
      end
    end

    context "as an enterprise user" do
      let!(:user) { create(:user) }
      let!(:enterprise1) { create(:enterprise, sells: 'any', owner: user) }
      let!(:enterprise2) { create(:enterprise, sells: 'own', owner: user) }
      let!(:enterprise3) { create(:enterprise, sells: 'any', owner: create(:user) ) }

      before do
        allow(controller).to receive_messages spree_current_user: user
      end

      context "html" do
        it "returns an empty @collection" do
          get :index, format: :html
          expect(assigns(:collection)).to eq []
        end
      end

      context "json" do
        it "scopes @collection to enterprises editable by the user" do
          get :index, format: :json
          expect(assigns(:collection)).to include enterprise1, enterprise2
          expect(assigns(:collection)).to_not include enterprise3
        end
      end
    end
  end
end
