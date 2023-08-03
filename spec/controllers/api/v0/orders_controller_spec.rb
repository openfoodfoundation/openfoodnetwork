# frozen_string_literal: true

require 'spec_helper'

module Api
  describe V0::OrdersController, type: :controller do
    include AuthenticationHelper
    render_views

    let!(:regular_user) { create(:user) }
    let!(:admin_user) { create(:admin_user) }

    let!(:distributor) { create(:distributor_enterprise) }
    let!(:coordinator) { create(:distributor_enterprise) }
    let!(:order_cycle) { create(:simple_order_cycle, coordinator: coordinator) }

    describe '#index' do
      let!(:distributor2) { create(:distributor_enterprise) }
      let!(:coordinator2) { create(:distributor_enterprise) }
      let!(:supplier) { create(:supplier_enterprise) }
      let!(:order_cycle2) { create(:simple_order_cycle, coordinator: coordinator2) }
      let!(:order1) do
        create(:order, order_cycle: order_cycle, state: 'complete', completed_at: Time.zone.now,
                       distributor: distributor, billing_address: create(:address, lastname: "c"),
                       total: 5.0)
      end
      let!(:order2) do
        create(:order, order_cycle: order_cycle, state: 'complete', completed_at: Time.zone.now,
                       distributor: distributor2, billing_address: create(:address, lastname: "a"),
                       total: 10.0)
      end
      let!(:order3) do
        create(:order, order_cycle: order_cycle, state: 'complete', completed_at: Time.zone.now,
                       distributor: distributor, billing_address: create(:address, lastname: "b"),
                       total: 1.0 )
      end
      let!(:order4) do
        create(:completed_order_with_fees, order_cycle: order_cycle2, distributor: distributor2,
                                           billing_address: create(:address, lastname: "d"),
                                           total: 15.0)
      end
      let!(:order5) { create(:order, state: 'cart', completed_at: nil) }
      let!(:line_item1) do
        create(:line_item_with_shipment, order: order1,
                                         product: create(:product, supplier: supplier))
      end
      let!(:line_item2) do
        create(:line_item_with_shipment, order: order2,
                                         product: create(:product, supplier: supplier))
      end
      let!(:line_item3) do
        create(:line_item_with_shipment, order: order2,
                                         product: create(:product, supplier: supplier))
      end
      let!(:line_item4) do
        create(:line_item_with_shipment, order: order3,
                                         product: create(:product, supplier: supplier))
      end

      context 'as a regular user' do
        before do
          allow(controller).to receive(:spree_current_user) { regular_user }
          get :index
        end

        it "returns unauthorized" do
          assert_unauthorized!
        end
      end

      context 'as an admin user' do
        before do
          allow(controller).to receive(:spree_current_user) { admin_user }
        end

        it "retrieves a list of orders with appropriate attributes,
            including line items with appropriate attributes" do
          get :index
          returns_orders(json_response)
        end
      end

      context 'as an enterprise user' do
        context 'producer enterprise' do
          before do
            allow(controller).to receive(:spree_current_user) { supplier.owner }
            get :index
          end

          it "does not display line items for which my enterprise is a supplier" do
            assert_unauthorized!
          end
        end

        context 'coordinator enterprise' do
          before do
            allow(controller).to receive(:spree_current_user) { coordinator.owner }
            get :index
          end

          it "retrieves a list of orders" do
            returns_orders(json_response)
          end
        end

        context 'hub enterprise' do
          before do
            allow(controller).to receive(:spree_current_user) { distributor.owner }
            get :index
          end

          it "retrieves a list of orders" do
            returns_orders(json_response)
          end
        end
      end

      context 'using search filters' do
        before do
          allow(controller).to receive(:spree_current_user) { admin_user }
        end

        it 'can show only completed orders' do
          get :index, params: { q: { completed_at_not_null: true, s: 'created_at desc' } },
                      as: :json

          expect(json_response['orders']).to eq serialized_orders([order4, order3, order2, order1])
        end
      end

      context 'sorting' do
        before do
          allow(controller).to receive(:spree_current_user) { admin_user }
        end

        it 'can sort orders by total' do
          get :index, params: { q: { completed_at_not_null: true, s: 'total desc' } },
                      as: :json

          expect(json_response['orders']).to eq serialized_orders([order4, order2, order1, order3])
        end

        it 'can sort orders by bill_address.lastname' do
          get :index, params: { q: { completed_at_not_null: true,
                                     s: 'bill_address_lastname ASC' } },
                      as: :json

          expect(json_response['orders']
            .map{ |o| o[:id] }).to eq serialized_orders([order2, order3, order1, order4])
              .map{ |o| o["id"] }
        end
      end

      context 'with pagination' do
        before do
          allow(controller).to receive(:spree_current_user) { distributor.owner }
        end

        it 'returns pagination data when query params contain :per_page]' do
          get :index, params: { per_page: 15, page: 1 }

          pagination_data = {
            'results' => 2,
            'pages' => 1,
            'page' => 1,
            'per_page' => 15
          }

          expect(json_response['pagination']).to eq pagination_data
        end
      end
    end

    describe "#show" do
      let!(:order) {
        create(:completed_order_with_totals, order_cycle: order_cycle, distributor: distributor )
      }

      context "Resource not found" do
        before { allow(controller).to receive(:spree_current_user) { admin_user } }

        it "when no order number is given" do
          get :show, params: { id: "" }
          expect(response).to have_http_status(:not_found)
        end

        it "when order number given is not in the systen" do
          get :show, params: { id: "X1321313232" }
          expect(response).to have_http_status(:not_found)
        end
      end

      context "access" do
        it "returns unauthorized, as a regular user" do
          allow(controller).to receive(:spree_current_user) { regular_user }
          get :show, params: { id: order.number }
          assert_unauthorized!
        end

        it "returns the order, as an admin user" do
          allow(controller).to receive(:spree_current_user) { admin_user }
          get :show, params: { id: order.number }
          expect_order
        end

        it "returns the order, as the order distributor owner" do
          allow(controller).to receive(:spree_current_user) { order.distributor.owner }
          get :show, params: { id: order.number }
          expect_order
        end

        it "returns unauthorized, as the order product's supplier owner" do
          allow(controller).to receive(:spree_current_user) {
                                 order.line_items.first.variant.product.supplier.owner
                               }
          get :show, params: { id: order.number }
          assert_unauthorized!
        end

        it "returns the order, as the Order Cycle coorinator owner" do
          allow(controller).to receive(:spree_current_user) { order.order_cycle.coordinator.owner }
          get :show, params: { id: order.number }
          expect_order
        end
      end

      context "as distributor owner" do
        let!(:order) {
          create(:completed_order_with_fees, order_cycle: order_cycle, distributor: distributor )
        }

        before { allow(controller).to receive(:spree_current_user) { order.distributor.owner } }

        it "can view an order not in a standard state" do
          order.update(completed_at: nil, state: 'shipped')
          get :show, params: { id: order.number }
          expect_order
        end

        it "can view an order with weight calculator (this validates case " \
           "where options[current_order] is nil on the shipping method serializer)" do
          order.shipping_method.update_attribute(:calculator,
                                                 create(:weight_calculator, calculable: order))
          allow(controller).to receive(:current_order).and_return order
          get :show, params: { id: order.number }
          expect_order
        end

        it "returns an order with all required fields" do
          get :show, params: { id: order.number }

          expect_order
          expect(json_response.symbolize_keys.keys).to include(*order_detailed_attributes)

          expect(json_response[:bill_address]).to include(
            'address1' => order.bill_address.address1,
            'lastname' => order.bill_address.lastname
          )
          expect(json_response[:ship_address]).to include(
            'address1' => order.ship_address.address1,
            'lastname' => order.ship_address.lastname
          )
          expect(json_response[:shipping_method][:name]).to eq order.shipping_method.name

          expect(json_response[:adjustments].first).to include(
            'label' => "Transaction fee",
            'amount' => order.all_adjustments.payment_fee.first.amount.to_s
          )
          expect(json_response[:adjustments].second).to include(
            'label' => "Shipping",
            'amount' => order.shipment_adjustments.first.amount.to_s
          )

          expect(json_response[:payments].first[:amount]).to eq order.payments.first.amount.to_s
          expect(json_response[:line_items].size).to eq order.line_items.size
          expect(json_response[:line_items].first[:variant][:product_name])
            .to eq order.line_items.first.variant.product.name
          expect(json_response[:line_items].first[:tax_category_id])
            .to eq order.line_items.first.variant.tax_category_id
        end
      end
    end

    describe "#capture and #ship actions" do
      let(:user) { create(:user) }
      let(:product) { create(:simple_product) }
      let(:distributor) { create(:distributor_enterprise, owner: user) }
      let(:order_cycle) {
        create(:simple_order_cycle,
               distributors: [distributor], variants: [product.variants.first])
      }
      let!(:order) {
        create(:order_with_totals_and_distribution,
               user: user, distributor: distributor, order_cycle: order_cycle,
               state: 'complete', payment_state: 'balance_due')
      }

      before do
        order.finalize!
        order.payments << create(:check_payment, order: order, amount: order.total)
        allow(controller).to receive(:spree_current_user) { order.distributor.owner }
      end

      describe "#capture" do
        it "captures payments and returns an updated order object" do
          put :capture, params: { id: order.number }

          expect(order.reload.pending_payments.empty?).to be true
          expect_order
        end

        context "when payment is not required" do
          before do
            allow_any_instance_of(Spree::Order).to receive(:payment_required?) { false }
          end

          it "returns an error" do
            put :capture, params: { id: order.number }

            expect(json_response['error'])
              .to eq 'Payment could not be processed, please check the details you entered'
          end
        end
      end

      describe "#ship" do
        before do
          order.payments.first.capture!
        end

        it "marks orders as shipped and returns an updated order object" do
          put :ship, params: { id: order.number }

          expect(order.reload.shipments.any?(&:shipped?)).to be true
          expect_order
        end
      end
    end

    private

    def expect_order
      expect(response.status).to eq 200
      expect(json_response[:number]).to eq order.number
    end

    def serialized_orders(orders)
      serialized_orders = ActiveModel::ArraySerializer.new(
        orders,
        each_serializer: Api::Admin::OrderSerializer,
        root: false
      )

      JSON.parse(serialized_orders.to_json)
    end

    def returns_orders(response)
      keys = response['orders'].first.keys.map(&:to_sym)
      expect(order_attributes.all?{ |attr| keys.include? attr }).to be_truthy
    end

    def order_attributes
      [
        :id, :number, :full_name, :email, :phone, :completed_at, :display_total,
        :edit_path, :state, :payment_state, :shipment_state,
        :payments_path, :ready_to_ship, :ready_to_capture, :created_at,
        :distributor_name, :special_instructions
      ]
    end

    def order_detailed_attributes
      [
        :number, :item_total, :total, :state, :adjustment_total, :payment_total,
        :completed_at, :shipment_state, :payment_state, :email, :special_instructions
      ]
    end
  end
end
