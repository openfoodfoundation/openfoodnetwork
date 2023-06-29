# frozen_string_literal: true

require 'spec_helper'

describe Admin::SubscriptionLineItemsController, type: :controller do
  include AuthenticationHelper

  describe "build" do
    let(:user) { create(:user) }
    let!(:shop) { create(:enterprise, owner: user) }
    let(:unmanaged_shop) { create(:enterprise) }
    let!(:product) { create(:product) }
    let!(:variant) {
      create(:variant, product: product, unit_value: '100', price: 15.00)
    }
    let!(:outgoing_exchange) {
      order_cycle.exchanges.create(sender: shop, receiver: shop, variants: [variant],
                                   enterprise_fees: [enterprise_fee])
    }
    let!(:enterprise_fee) { create(:enterprise_fee, amount: 3.50) }
    let!(:order_cycle) {
      create(:simple_order_cycle, coordinator: shop, orders_open_at: 2.days.from_now,
                                  orders_close_at: 7.days.from_now)
    }
    let!(:schedule) { create(:schedule, order_cycles: [order_cycle]) }
    let(:unmanaged_schedule) {
      create(:schedule, order_cycles: [create(:simple_order_cycle, coordinator: unmanaged_shop)])
    }

    context "json" do
      let(:params) {
        { format: :json, subscription_line_item: { quantity: 2, variant_id: variant.id } }
      }

      context 'as an enterprise user' do
        before { allow(controller).to receive(:spree_current_user) { user } }

        context "but no shop_id is provided" do
          it "returns an error" do
            spree_post :build, params
            expect(JSON.parse(response.body)['errors']).to eq ['Unauthorised']
          end
        end

        context "and an unmanaged shop_id is provided" do
          before { params.merge!(shop_id: unmanaged_shop.id) }

          it "returns an error" do
            spree_post :build, params
            expect(JSON.parse(response.body)['errors']).to eq ['Unauthorised']
          end
        end

        context "where a managed shop_id is provided" do
          before { params.merge!(shop_id: shop.id) }

          context "but the shop doesn't have permission to sell product in question" do
            let!(:outgoing_exchange) {}

            it "returns an error" do
              spree_post :build, params
              json_response = JSON.parse(response.body)
              expect(json_response['errors'])
                .to eq ["#{shop.name} is not permitted to sell the selected product"]
            end
          end

          context "and the shop has permission to sell the product in question" do
            before do
              product.update_attribute(:supplier_id, shop.id)
            end

            context "but no schedule_id is provided" do
              it "returns a serialized subscription line item without a price estimate" do
                spree_post :build, params

                json_response = JSON.parse(response.body)
                expect(json_response['price_estimate']).to eq '?'
                expect(json_response['quantity']).to eq 2
                expect(json_response['description']).to eq "#{variant.product.name} - 100g"
              end
            end

            context "but an unmanaged schedule_id is provided" do
              before { params.merge!(schedule_id: unmanaged_schedule.id) }

              it "returns a serialized subscription line item without a price estimate" do
                spree_post :build, params

                json_response = JSON.parse(response.body)
                expect(json_response['price_estimate']).to eq '?'
                expect(json_response['quantity']).to eq 2
                expect(json_response['description']).to eq "#{variant.product.name} - 100g"
              end
            end

            context "and a managed schedule_id is provided" do
              before { params.merge!(schedule_id: schedule.id) }

              context "where no relevant variant override exists" do
                it "returns a serialized subscription line item with a price estimate, " \
                   "based on the variant" do
                  spree_post :build, params

                  json_response = JSON.parse(response.body)
                  expect(json_response['price_estimate']).to eq 18.5
                  expect(json_response['quantity']).to eq 2
                  expect(json_response['description']).to eq "#{variant.product.name} - 100g"
                end
              end

              context "where a relevant variant override exists" do
                let!(:override) {
                  create(:variant_override, hub_id: shop.id, variant_id: variant.id, price: 12.00)
                }

                it "returns a serialized subscription line item with a price estimate, " \
                   "based on the override" do
                  spree_post :build, params

                  json_response = JSON.parse(response.body)
                  expect(json_response['price_estimate']).to eq 15.5
                  expect(json_response['quantity']).to eq 2
                  expect(json_response['description']).to eq "#{variant.product.name} - 100g"
                end
              end
            end
          end
        end
      end
    end
  end
end
