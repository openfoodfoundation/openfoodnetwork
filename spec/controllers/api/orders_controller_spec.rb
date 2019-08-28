require 'spec_helper'

module Api
  describe OrdersController, type: :controller do
    include AuthenticationWorkflow
    render_views

    describe '#index' do
      let!(:distributor) { create(:distributor_enterprise) }
      let!(:distributor2) { create(:distributor_enterprise) }
      let!(:supplier) { create(:supplier_enterprise) }
      let!(:coordinator) { create(:distributor_enterprise) }
      let!(:coordinator2) { create(:distributor_enterprise) }
      let!(:order_cycle) { create(:simple_order_cycle, coordinator: coordinator) }
      let!(:order_cycle2) { create(:simple_order_cycle, coordinator: coordinator2) }
      let!(:order1) do
        create(:order, order_cycle: order_cycle, state: 'complete', completed_at: Time.zone.now,
                       distributor: distributor, billing_address: create(:address) )
      end
      let!(:order2) do
        create(:order, order_cycle: order_cycle, state: 'complete', completed_at: Time.zone.now,
                       distributor: distributor2, billing_address: create(:address) )
      end
      let!(:order3) do
        create(:order, order_cycle: order_cycle, state: 'complete', completed_at: Time.zone.now,
                       distributor: distributor, billing_address: create(:address) )
      end
      let!(:order4) do
        create(:completed_order_with_fees, order_cycle: order_cycle2, distributor: distributor2)
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
      let!(:regular_user) { create(:user) }
      let!(:admin_user) { create(:admin_user) }

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
          get :index
        end

        it "retrieves a list of orders with appropriate attributes,
            including line items with appropriate attributes" do

          returns_orders(json_response)
        end

        it "formats completed_at to 'yyyy-mm-dd hh:mm'" do
          completed_dates = json_response['orders'].map{ |order| order['completed_at'] }
          correct_formats = completed_dates.all?{ |a| a == order1.completed_at.strftime('%B %d, %Y') }

          expect(correct_formats).to be_truthy
        end

        it "returns distributor object with id key" do
          distributors = json_response['orders'].map{ |order| order['distributor'] }
          expect(distributors.all?{ |d| d.key?('id') }).to be_truthy
        end

        it "returns the order number" do
          order_numbers = json_response['orders'].map{ |order| order['number'] }
          expect(order_numbers.all?{ |number| number.match("^R\\d{5,10}$") }).to be_truthy
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
          get :index, format: :json, q: { completed_at_not_null: true, s: 'created_at desc' }

          expect(json_response['orders']).to eq serialized_orders([order4, order3, order2, order1])
        end
      end

      context 'with pagination' do
        before do
          allow(controller).to receive(:spree_current_user) { distributor.owner }
        end

        it 'returns pagination data when query params contain :per_page]' do
          get :index, per_page: 15, page: 1

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

    private

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
        :payments_path, :ship_path, :ready_to_ship, :created_at,
        :distributor_name, :special_instructions, :payment_capture_path
      ]
    end
  end
end
