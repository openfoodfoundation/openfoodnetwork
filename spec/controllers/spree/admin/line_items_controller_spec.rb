require 'spec_helper'

describe Spree::Admin::LineItemsController do
  include AuthenticationWorkflow

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

  describe '#update' do
    let(:supplier) { create(:supplier_enterprise) }
    let(:distributor1) { create(:distributor_enterprise) }
    let(:coordinator) { create(:distributor_enterprise) }
    let(:order_cycle) { create(:simple_order_cycle, coordinator: coordinator) }
    let!(:order1) { FactoryGirl.create(:order, order_cycle: order_cycle, state: 'complete', completed_at: Time.zone.now, distributor: distributor1, billing_address: FactoryGirl.create(:address) ) }
    let!(:line_item1) { FactoryGirl.create(:line_item, order: order1, product: FactoryGirl.create(:product, supplier: supplier)) }
    let(:line_item_params) { { quantity: 3, final_weight_volume: 3000, price: 3.00 } }
    let(:params) { { id: line_item1.id, order_id: order1.number, line_item: line_item_params } }

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

        # Used in admin/orders/edit
        context 'when the request is JS/XHR (jquery-rails gem)' do
          it "updates the line item" do
            xhr :put, :update, params
            line_item1.reload
            expect(line_item1.quantity).to eq 3
            expect(line_item1.final_weight_volume).to eq 3000
            expect(line_item1.price).to eq 3.00
          end

          it "returns an empty JSON response" do
            xhr :put, :update, params
            expect(response.body).to eq ' '
          end

          it 'returns a 204 response' do
            xhr :put, :update, params
            expect(response.status).to eq 204
          end

          context 'when the line item params are not correct' do
            let(:line_item_params) { { price: 'hola' } }
            let(:errors) { { 'price' => ['is not a number'] } }

            it 'returns a JSON with the errors' do
              xhr :put, :update, params
              expect(JSON.parse(response.body)['errors']).to eq(errors)
            end

            it 'returns a 412 response' do
              xhr :put, :update, params
              expect(response.status).to eq 412
            end
          end
        end

        context 'when the request is HTML' do
          before { params[:format] = :html }

          it 'returns an HTML response with the order form' do
            spree_put :update, params
            expect(response.body).to match(/admin_order_form_fields/)
          end
        end
      end

      context "hub enterprise" do
        before do
          controller.stub spree_current_user: distributor1.owner
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
end
