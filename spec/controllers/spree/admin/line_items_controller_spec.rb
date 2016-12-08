require 'spec_helper'

describe Spree::Admin::LineItemsController do
  include AuthenticationWorkflow

  describe "#index" do
    render_views

    let(:line_item_attributes) { [:id, :quantity, :max_quantity, :price, :supplier, :final_weight_volume, :units_product, :units_variant, :order] }
    let!(:dist1) { FactoryGirl.create(:distributor_enterprise) }
    let!(:order1) { FactoryGirl.create(:order, state: 'complete', completed_at: 1.day.ago, distributor: dist1, billing_address: FactoryGirl.create(:address) ) }
    let!(:order2) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.zone.now, distributor: dist1, billing_address: FactoryGirl.create(:address) ) }
    let!(:order3) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.zone.now, distributor: dist1, billing_address: FactoryGirl.create(:address) ) }
    let!(:line_item1) { FactoryGirl.create(:line_item, order: order1) }
    let!(:line_item2) { FactoryGirl.create(:line_item, order: order2) }
    let!(:line_item3) { FactoryGirl.create(:line_item, order: order2) }
    let!(:line_item4) { FactoryGirl.create(:line_item, order: order3) }

    context "as a normal user" do
      before { controller.stub spree_current_user: create_enterprise_user }

      it "should deny me access to the index action" do
        spree_get :index, :format => :json
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context "as an administrator" do

      before do
        controller.stub spree_current_user: quick_login_as_admin
      end

      context "when no ransack params are passed in" do
        before do
          spree_get :index, :format => :json
        end

        it "retrieves a list of line_items with appropriate attributes, including line items with appropriate attributes" do
          keys = json_response.first.keys.map{ |key| key.to_sym }
          line_item_attributes.all?{ |attr| keys.include? attr }.should == true
        end

        it "sorts line_items in ascending id line_item" do
          ids = json_response.map{ |line_item| line_item['id'] }
          ids[0].should < ids[1]
          ids[1].should < ids[2]
        end

        it "formats final_weight_volume as a float" do
          json_response.map{ |line_item| line_item['final_weight_volume'] }.all?{ |fwv| fwv.is_a?(Float) }.should == true
        end

        it "returns distributor object with id key" do
          json_response.map{ |line_item| line_item['supplier'] }.all?{ |d| d.has_key?('id') }.should == true
        end
      end

      context "when ransack params are passed in for line items" do
        before do
          spree_get :index, :format => :json, q: { order_id_eq: order2.id }
        end

        it "retrives a list of line items which match the criteria" do
          expect(json_response.map{ |line_item| line_item['id'] }).to eq [line_item2.id, line_item3.id]
        end
      end

      context "when ransack params are passed in for orders" do
        before do
          spree_get :index, :format => :json, q: { order: { completed_at_gt: 2.hours.ago } }
        end

        it "retrives a list of line items whose orders match the criteria" do
          expect(json_response.map{ |line_item| line_item['id'] }).to eq [line_item2.id, line_item3.id, line_item4.id]
        end
      end
    end

    context "as an enterprise user" do
      let(:supplier) { create(:supplier_enterprise) }
      let(:distributor1) { create(:distributor_enterprise) }
      let(:distributor2) { create(:distributor_enterprise) }
      let(:coordinator) { create(:distributor_enterprise) }
      let(:order_cycle) { create(:simple_order_cycle, coordinator: coordinator) }
      let!(:order1) { FactoryGirl.create(:order, order_cycle: order_cycle, state: 'complete', completed_at: Time.zone.now, distributor: distributor1, billing_address: FactoryGirl.create(:address) ) }
      let!(:line_item1) { FactoryGirl.create(:line_item, order: order1, product: FactoryGirl.create(:product, supplier: supplier)) }
      let!(:line_item2) { FactoryGirl.create(:line_item, order: order1, product: FactoryGirl.create(:product, supplier: supplier)) }
      let!(:order2) { FactoryGirl.create(:order, order_cycle: order_cycle, state: 'complete', completed_at: Time.zone.now, distributor: distributor2, billing_address: FactoryGirl.create(:address) ) }
      let!(:line_item3) { FactoryGirl.create(:line_item, order: order2, product: FactoryGirl.create(:product, supplier: supplier)) }

      context "producer enterprise" do
        before do
          controller.stub spree_current_user: supplier.owner
          spree_get :index, :format => :json
        end

        it "does not display line items for which my enterprise is a supplier" do
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "coordinator enterprise" do
        before do
          controller.stub spree_current_user: coordinator.owner
          spree_get :index, :format => :json
        end

        it "retrieves a list of line_items" do
          keys = json_response.first.keys.map{ |key| key.to_sym }
          line_item_attributes.all?{ |attr| keys.include? attr }.should == true
        end
      end

      context "hub enterprise" do
        before do
          controller.stub spree_current_user: distributor1.owner
          spree_get :index, :format => :json
        end

        it "retrieves a list of line_items" do
          keys = json_response.first.keys.map{ |key| key.to_sym }
          line_item_attributes.all?{ |attr| keys.include? attr }.should == true
        end
      end
    end
  end

  describe "#create" do
    let!(:variant) { create(:variant, price: 88) }
    let!(:vo) { create(:variant_override, hub: distributor, variant: variant, price: 11.11) }
    let!(:distributor) { create(:distributor_enterprise) }
    let!(:order_cycle) { create(:simple_order_cycle, distributors: [distributor], variants: [variant]) }
    let!(:order) { create(:order, distributor: distributor, order_cycle: order_cycle) }
    let(:params) { { order_id: order.number, line_item: { variant_id: variant.id, quantity: 1 } } }

    before { login_as_admin }

    it "takes variant overrides into account for price" do
      spree_post :create, params

      order.line_items(:reload).last.price.should == 11.11
    end
  end

  describe "#update" do
    let(:supplier) { create(:supplier_enterprise) }
    let(:distributor1) { create(:distributor_enterprise) }
    let(:coordinator) { create(:distributor_enterprise) }
    let(:order_cycle) { create(:simple_order_cycle, coordinator: coordinator) }
    let!(:order1) { FactoryGirl.create(:order, order_cycle: order_cycle, state: 'complete', completed_at: Time.zone.now, distributor: distributor1, billing_address: FactoryGirl.create(:address) ) }
    let!(:line_item1) { FactoryGirl.create(:line_item, order: order1, product: FactoryGirl.create(:product, supplier: supplier)) }
    let(:params) { { format: :json, id: line_item1.id, order_id: order1.number, line_item: { quantity: 3, final_weight_volume: 3000, price: 3.00 } } }

    context "as an enterprise user" do
      context "producer enterprise" do
        before do
          controller.stub spree_current_user: supplier.owner
          spree_put :update, params
        end

        it "does not allow access" do
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "coordinator enterprise" do
        render_views

        before do
          controller.stub spree_current_user: coordinator.owner
        end

        it "updates the line item" do
          spree_put :update, params
          line_item1.reload
          expect(line_item1.quantity).to eq 3
          expect(line_item1.final_weight_volume).to eq 3000
          expect(line_item1.price).to eq 3.00
        end

        it "returns an empty JSON response" do
          spree_put :update, params.merge(format: :json)
          expect(response.body).to eq ' '
        end

        it "returns an HTML response with the order form" do
          spree_put :update, params.merge(format: :html)
          expect(response.body).to match /admin_order_form_fields/
        end
      end

      context "hub enterprise" do
        before do
          controller.stub spree_current_user: distributor1.owner
          spree_put :update, params
        end

        it "updates the line item" do
          line_item1.reload
          expect(line_item1.quantity).to eq 3
          expect(line_item1.final_weight_volume).to eq 3000
          expect(line_item1.price).to eq 3.00
        end
      end
    end
  end

  describe "#destroy" do
    render_views

    let(:supplier) { create(:supplier_enterprise) }
    let(:distributor1) { create(:distributor_enterprise) }
    let(:coordinator) { create(:distributor_enterprise) }
    let(:order_cycle) { create(:simple_order_cycle, coordinator: coordinator) }
    let!(:order1) { FactoryGirl.create(:order, order_cycle: order_cycle, state: 'complete', completed_at: Time.zone.now, distributor: distributor1, billing_address: FactoryGirl.create(:address) ) }
    let!(:line_item1) { FactoryGirl.create(:line_item, order: order1, product: FactoryGirl.create(:product, supplier: supplier)) }
    let(:params) { { format: :json, id: line_item1.id, order_id: order1.number } }

    before do
      controller.stub spree_current_user: coordinator.owner
    end

    it "destroys the line item" do
      expect {
        spree_delete :destroy, params
      }.to change { Spree::LineItem.where(id: line_item1).count }.from(1).to(0)
    end

    it "returns an empty JSON response" do
      spree_delete :destroy, params.merge(format: :json)
      expect(response.body).to eq ' '
    end

    it "returns an HTML response with the order form" do
      spree_delete :destroy, params.merge(format: :html)
      expect(response.body).to match /admin_order_form_fields/
    end
  end
end
