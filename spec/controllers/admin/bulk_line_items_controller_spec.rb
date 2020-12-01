require 'spec_helper'

describe Admin::BulkLineItemsController, type: :controller do
  describe '#index' do
    render_views

    let(:line_item_attributes) { %i[id quantity max_quantity price supplier final_weight_volume units_product units_variant order] }
    let!(:dist1) { FactoryBot.create(:distributor_enterprise) }
    let!(:order1) { FactoryBot.create(:order, state: 'complete', completed_at: 1.day.ago, distributor: dist1, billing_address: FactoryBot.create(:address) ) }
    let!(:order2) { FactoryBot.create(:order, state: 'complete', completed_at: Time.zone.now, distributor: dist1, billing_address: FactoryBot.create(:address) ) }
    let!(:order3) { FactoryBot.create(:order, state: 'complete', completed_at: Time.zone.now, distributor: dist1, billing_address: FactoryBot.create(:address) ) }
    let!(:line_item1) { FactoryBot.create(:line_item_with_shipment, order: order1) }
    let!(:line_item2) { FactoryBot.create(:line_item_with_shipment, order: order2) }
    let!(:line_item3) { FactoryBot.create(:line_item_with_shipment, order: order2) }
    let!(:line_item4) { FactoryBot.create(:line_item_with_shipment, order: order3) }

    context "as a normal user" do
      before { allow(controller).to receive_messages spree_current_user: create(:user) }

      it "should deny me access to the index action" do
        spree_get :index, format: :json
        expect(response).to redirect_to unauthorized_path
      end
    end

    context "as an administrator" do
      before do
        allow(controller).to receive_messages spree_current_user: create(:admin_user)
      end

      context "when no ransack params are passed in" do
        before do
          spree_get :index, format: :json
        end

        it "retrieves a list of line_items with appropriate attributes, including line items with appropriate attributes" do
          keys = json_response['line_items'].first.keys.map(&:to_sym)
          expect(line_item_attributes.all?{ |attr| keys.include? attr }).to eq(true)
        end

        it "sorts line_items in ascending id line_item" do
          expect(line_item_ids[0]).to be < line_item_ids[1]
          expect(line_item_ids[1]).to be < line_item_ids[2]
        end

        it "formats final_weight_volume as a float" do
          expect(json_response['line_items'].map{ |line_item| line_item['final_weight_volume'] }.all?{ |fwv| fwv.is_a?(Float) }).to eq(true)
        end

        it "returns distributor object with id key" do
          expect(json_response['line_items'].map{ |line_item| line_item['supplier'] }.all?{ |d| d.key?('id') }).to eq(true)
        end
      end

      context "when ransack params are passed in for line items" do
        before do
          spree_get :index, format: :json, q: { order_id_eq: order2.id }
        end

        it "retrives a list of line items which match the criteria" do
          expect(line_item_ids).to eq [line_item2.id, line_item3.id]
        end
      end

      context "when ransack params are passed in for orders" do
        before do
          spree_get :index, format: :json, q: { order: { completed_at_gt: 2.hours.ago } }
        end

        it "retrives a list of line items whose orders match the criteria" do
          expect(line_item_ids).to eq [line_item2.id, line_item3.id, line_item4.id]
        end
      end
    end

    context "as an enterprise user" do
      let(:supplier) { create(:supplier_enterprise) }
      let(:distributor1) { create(:distributor_enterprise) }
      let(:distributor2) { create(:distributor_enterprise) }
      let(:coordinator) { create(:distributor_enterprise) }
      let(:order_cycle) { create(:simple_order_cycle, coordinator: coordinator) }
      let!(:order1) { FactoryBot.create(:order, order_cycle: order_cycle, state: 'complete', completed_at: Time.zone.now, distributor: distributor1, billing_address: FactoryBot.create(:address) ) }
      let!(:line_item1) { FactoryBot.create(:line_item_with_shipment, order: order1, product: FactoryBot.create(:product, supplier: supplier)) }
      let!(:line_item2) { FactoryBot.create(:line_item_with_shipment, order: order1, product: FactoryBot.create(:product, supplier: supplier)) }
      let!(:order2) { FactoryBot.create(:order, order_cycle: order_cycle, state: 'complete', completed_at: Time.zone.now, distributor: distributor2, billing_address: FactoryBot.create(:address) ) }
      let!(:line_item3) { FactoryBot.create(:line_item_with_shipment, order: order2, product: FactoryBot.create(:product, supplier: supplier)) }

      context "producer enterprise" do
        before do
          allow(controller).to receive_messages spree_current_user: supplier.owner
          spree_get :index, format: :json
        end

        it "does not display line items for which my enterprise is a supplier" do
          expect(response).to redirect_to unauthorized_path
        end
      end

      context "coordinator enterprise" do
        before do
          allow(controller).to receive_messages spree_current_user: coordinator.owner
          spree_get :index, format: :json
        end

        it "retrieves a list of line_items" do
          keys = json_response['line_items'].first.keys.map(&:to_sym)
          expect(line_item_attributes.all?{ |attr| keys.include? attr }).to eq(true)
        end
      end

      context "hub enterprise" do
        before do
          allow(controller).to receive_messages spree_current_user: distributor1.owner
          spree_get :index, format: :json
        end

        it "retrieves a list of line_items" do
          keys = json_response['line_items'].first.keys.map(&:to_sym)
          expect(line_item_attributes.all?{ |attr| keys.include? attr }).to eq(true)
        end
      end
    end

    context "paginating" do
      before do
        allow(controller).to receive_messages spree_current_user: create(:admin_user)
      end

      context "with pagination args" do
        it "returns paginated results" do
          spree_get :index, { page: 1, per_page: 2 }, format: :json

          expect(line_item_ids).to eq [line_item1.id, line_item2.id]
          expect(json_response['pagination']).to eq(
            { 'page' => 1, 'per_page' => 2, 'pages' => 2, 'results' => 4 }
          )
        end

        it "returns paginated results for a second page" do
          spree_get :index, { page: 2, per_page: 2 }, format: :json

          expect(line_item_ids).to eq [line_item3.id, line_item4.id]
          expect(json_response['pagination']).to eq(
            { 'page' => 2, 'per_page' => 2, 'pages' => 2, 'results' => 4 }
          )
        end
      end
    end
  end

  describe '#update' do
    let(:supplier) { create(:supplier_enterprise) }
    let(:distributor1) { create(:distributor_enterprise) }
    let(:coordinator) { create(:distributor_enterprise) }
    let(:order_cycle) { create(:simple_order_cycle, coordinator: coordinator) }
    let!(:order1) { FactoryBot.create(:order, order_cycle: order_cycle, state: 'complete', completed_at: Time.zone.now, distributor: distributor1, billing_address: FactoryBot.create(:address) ) }
    let!(:line_item1) {
      line_item1 = FactoryBot.create(:line_item_with_shipment, order: order1, product: FactoryBot.create(:product, supplier: supplier))
      # make sure shipment is available through db reloads of this line_item
      line_item1.tap(&:save!)
    }
    let(:line_item_params) { { quantity: 3, final_weight_volume: 3000, price: 3.00 } }
    let(:params) { { id: line_item1.id, order_id: order1.number, line_item: line_item_params } }

    context "as an enterprise user" do
      context "producer enterprise" do
        before do
          allow(controller).to receive_messages spree_current_user: supplier.owner
          spree_put :update, params
        end

        it "does not allow access" do
          expect(response).to redirect_to unauthorized_path
        end
      end

      context "coordinator enterprise" do
        render_views

        before do
          allow(controller).to receive_messages spree_current_user: coordinator.owner
        end

        # Used in admin/orders/bulk_management
        context 'when the request is JSON (angular)' do
          before { params[:format] = :json }

          it "updates the line item" do
            spree_put :update, params
            line_item1.reload
            expect(line_item1.quantity).to eq 3
            expect(line_item1.final_weight_volume).to eq 3000
            expect(line_item1.price).to eq 3.00
          end

          it "returns an empty JSON response" do
            spree_put :update, params
            expect(response.body).to eq ""
          end

          it 'returns a 204 response' do
            spree_put :update, params
            expect(response.status).to eq 204
          end

          it 'applies enterprise fees locking the order with an exclusive row lock' do
            allow(Spree::LineItem)
              .to receive(:find).with(line_item1.id.to_s).and_return(line_item1)

            expect(line_item1.order).to receive(:reload).with(lock: true)
            expect(line_item1.order).to receive(:update_distribution_charge!)

            spree_put :update, params
          end

          context 'when the line item params are not correct' do
            let(:line_item_params) { { price: 'hola' } }
            let(:errors) { { 'price' => ['is not a number'] } }

            it 'returns a JSON with the errors' do
              spree_put :update, params
              expect(JSON.parse(response.body)['errors']).to eq(errors)
            end

            it 'returns a 412 response' do
              spree_put :update, params
              expect(response.status).to eq 412
            end
          end
        end
      end

      context "hub enterprise" do
        before do
          allow(controller).to receive_messages spree_current_user: distributor1.owner
          xhr :put, :update, params
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

  describe '#destroy' do
    render_views

    let(:supplier) { create(:supplier_enterprise) }
    let(:distributor1) { create(:distributor_enterprise) }
    let(:coordinator) { create(:distributor_enterprise) }
    let(:order_cycle) { create(:simple_order_cycle, coordinator: coordinator) }
    let!(:order1) { FactoryBot.create(:order, order_cycle: order_cycle, state: 'complete', completed_at: Time.zone.now, distributor: distributor1, billing_address: FactoryBot.create(:address) ) }
    let!(:line_item1) { FactoryBot.create(:line_item_with_shipment, order: order1, product: FactoryBot.create(:product, supplier: supplier)) }
    let(:params) { { id: line_item1.id, order_id: order1.number } }

    before do
      allow(controller).to receive_messages spree_current_user: coordinator.owner
    end

    # Used in admin/orders/bulk_management
    context 'when the request is JSON (angular)' do
      before { params[:format] = :json }

      it 'destroys the line item' do
        expect {
          spree_delete :destroy, params
        }.to change { Spree::LineItem.where(id: line_item1).count }.from(1).to(0)
      end

      it 'returns an empty JSON response' do
        spree_delete :destroy, params
        expect(response.body).to eq ""
      end

      it 'returns a 204 response' do
        spree_delete :destroy, params
        expect(response.status).to eq 204
      end
    end
  end

  private

  def line_item_ids
    json_response['line_items'].map{ |line_item| line_item['id'] }
  end
end
