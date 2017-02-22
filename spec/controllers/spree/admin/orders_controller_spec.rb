require 'spec_helper'

describe Spree::Admin::OrdersController, type: :controller do
  include AuthenticationWorkflow

  context "updating an order with line items" do
    let!(:order) { create(:order) }
    let(:line_item) { create(:line_item) }
    before { login_as_admin }

    it "updates distribution charges" do
      order.line_items << line_item
      order.save
      Spree::Order.any_instance.should_receive(:update_distribution_charge!)
      spree_put :update, {
        id: order,
        order: {
          number: order.number,
          distributor_id: order.distributor_id,
          order_cycle_id: order.order_cycle_id,
          line_items_attributes: [
            {
              id: line_item.id,
              quantity: line_item.quantity
            }
          ]
        }
      }
    end
  end

  describe "#index" do
    render_views

    let(:order_attributes) { [:id, :full_name, :email, :phone, :completed_at, :distributor, :order_cycle, :number] }

    def self.make_simple_data!
      let!(:dist1) { FactoryGirl.create(:distributor_enterprise) }
      let!(:order1) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.zone.now, distributor: dist1, billing_address: FactoryGirl.create(:address) ) }
      let!(:order2) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.zone.now, distributor: dist1, billing_address: FactoryGirl.create(:address) ) }
      let!(:order3) { FactoryGirl.create(:order, state: 'complete', completed_at: Time.zone.now, distributor: dist1, billing_address: FactoryGirl.create(:address) ) }
      let!(:line_item1) { FactoryGirl.create(:line_item, order: order1) }
      let!(:line_item2) { FactoryGirl.create(:line_item, order: order2) }
      let!(:line_item3) { FactoryGirl.create(:line_item, order: order2) }
      let!(:line_item4) { FactoryGirl.create(:line_item, order: order3) }
      let(:line_item_attributes) { [:id, :quantity, :max_quantity, :supplier, :units_product, :units_variant] }
    end

    context "as a normal user" do
      before { controller.stub spree_current_user: create_enterprise_user }

      make_simple_data!

      it "should deny me access to the index action" do
        spree_get :index, :format => :json
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context "as an administrator" do
      make_simple_data!

      before do
        controller.stub spree_current_user: quick_login_as_admin
        spree_get :index, :format => :json
      end

      it "retrieves a list of orders with appropriate attributes, including line items with appropriate attributes" do
        keys = json_response.first.keys.map{ |key| key.to_sym }
        order_attributes.all?{ |attr| keys.include? attr }.should == true
      end

      it "sorts orders in ascending id order" do
        ids = json_response.map{ |order| order['id'] }
        ids[0].should < ids[1]
        ids[1].should < ids[2]
      end

      it "formats completed_at to 'yyyy-mm-dd hh:mm'" do
        json_response.map{ |order| order['completed_at'] }.all?{ |a| a.match("^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}$") }.should == true
      end

      it "returns distributor object with id key" do
        json_response.map{ |order| order['distributor'] }.all?{ |d| d.has_key?('id') }.should == true
      end

      it "retrieves the order number" do
        json_response.map{ |order| order['number'] }.all?{ |number| number.match("^R\\d{5,10}$") }.should == true
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

        it "retrieves a list of orders" do
          keys = json_response.first.keys.map{ |key| key.to_sym }
          order_attributes.all?{ |attr| keys.include? attr }.should == true
        end
      end

      context "hub enterprise" do
        before do
          controller.stub spree_current_user: distributor1.owner
          spree_get :index, :format => :json
        end

        it "retrieves a list of orders" do
          keys = json_response.first.keys.map{ |key| key.to_sym }
          order_attributes.all?{ |attr| keys.include? attr }.should == true
        end
      end
    end
  end

  describe "#invoice" do
    let!(:user) { create(:user) }
    let!(:enterprise_user) { create(:user) }
    let!(:order) { create(:order_with_distributor, bill_address: create(:address), ship_address: create(:address)) }
    let!(:distributor) { order.distributor }
    let(:params) { { id: order.number } }

    context "as a normal user" do
      before { controller.stub spree_current_user: user }

      it "should prevent me from sending order invoices" do
        spree_get :invoice, params
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context "as an enterprise user" do
      context "which is not a manager of the distributor for an order" do
        before { controller.stub spree_current_user: user }
        it "should prevent me from sending order invoices" do
          spree_get :invoice, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "which is a manager of the distributor for an order" do
        before { controller.stub spree_current_user: distributor.owner }
        context "when the distributor's ABN has not been set" do
          before { distributor.update_attribute(:abn, "") }
          it "should allow me to send order invoices" do
            expect do
              spree_get :invoice, params
            end.to_not change{Spree::OrderMailer.deliveries.count}
            expect(response).to redirect_to spree.edit_admin_order_path(order)
            expect(flash[:error]).to eq "#{distributor.name} must have a valid ABN before invoices can be sent."
          end
        end

        context "when the distributor's ABN has been set" do
          before { distributor.update_attribute(:abn, "123") }
          before do
            Spree::MailMethod.create!(
              environment: Rails.env,
              preferred_mails_from: 'spree@example.com'
            )
          end
          it "should allow me to send order invoices" do
            expect do
              spree_get :invoice, params
            end.to change{Spree::OrderMailer.deliveries.count}.by(1)
            expect(response).to redirect_to spree.edit_admin_order_path(order)
          end
        end
      end
    end
  end

  describe "#print" do
    let!(:user) { create(:user) }
    let!(:enterprise_user) { create(:user) }
    let!(:order) { create(:order_with_distributor, bill_address: create(:address), ship_address: create(:address)) }
    let!(:distributor) { order.distributor }
    let(:params) { { id: order.number } }

    context "as a normal user" do
      before { controller.stub spree_current_user: user }

      it "should prevent me from sending order invoices" do
        spree_get :print, params
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context "as an enterprise user" do
      context "which is not a manager of the distributor for an order" do
        before { controller.stub spree_current_user: user }
        it "should prevent me from sending order invoices" do
          spree_get :print, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "which is a manager of the distributor for an order" do
        before { controller.stub spree_current_user: distributor.owner }
        it "should allow me to send order invoices" do
          spree_get :print, params
          expect(response).to render_template :invoice
        end
      end
    end
  end
end
