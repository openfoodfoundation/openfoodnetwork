# frozen_string_literal: true

require 'swagger_helper'

describe 'api/v0/orders', swagger_doc: 'v0/swagger.yaml', type: :request do
  path '/api/v0/orders' do
    get('list orders') do
      tags 'Orders'
      # type should be replaced with swagger 3.01 valid schema:
      # {type: string} when rswag #317 is resolved:
      # https://github.com/rswag/rswag/pull/319
      parameter name: 'X-Spree-Token', in: :header, type: :string
      parameter name: 'q[distributor_id_eq]', in: :query, type: :string, required: false,
                description: "Query orders for a specific distributor id."
      parameter name: 'q[completed_at_gt]', in: :query, type: :string, required: false,
                description: "Query orders completed after a date."
      parameter name: 'q[completed_at_lt]', in: :query, type: :string, required: false,
                description: "Query orders completed before a date."
      parameter name: 'q[state_eq]', in: :query, type: :string, required: false,
                description: "Query orders by order state, eg 'cart', 'complete'."
      parameter name: 'q[payment_state_eq]', in: :query, type: :string, required: false,
                description: "Query orders by order payment_state, eg 'balance_due', " \
                             "'paid', 'failed'."
      parameter name: 'q[email_cont]', in: :query, type: :string, required: false,
                description: "Query orders where the order email contains a string."
      parameter name: 'q[order_cycle_id_eq]', in: :query, type: :string, required: false,
                description: "Query orders for a specific order_cycle id."

      response(200, 'get orders') do
        # Adds model metadata for Swagger UI. Ideally we'd be able to just add:
        # schema '$ref' => '#/components/schemas/Order_Concise'
        # Which would also validate the response in the test, this is an open
        # issue with rswag: https://github.com/rswag/rswag/issues/268
        metadata[:response][:content] = {
          "application/json": {
            schema: { '$ref' => '#/components/schemas/Order_Concise' }
          }
        }
        context "when there are four orders with different properties set" do
          let!(:order_dist_1) {
            create(:order_with_distributor, email: "specific_name@example.com")
          }
          let!(:li1) { create(:line_item, order: order_dist_1) }
          let!(:order_dist_2) { create(:order_with_totals_and_distribution) }
          let!(:li2) { create(:line_item, order: order_dist_2) }
          let!(:order_dist_1_complete) {
            create(:completed_order_with_totals,  distributor: order_dist_1.distributor,
                                                  state: 'complete',
                                                  completed_at: Time.zone.today - 7.days,
                                                  line_items_count: 1)
          }
          let!(:order_dist_1_credit_owed) {
            create(:order, distributor: order_dist_1.distributor, payment_state: 'credit_owed',
                           completed_at: Time.zone.today)
          }
          let!(:li4) { create(:line_item_with_shipment, order: order_dist_1_credit_owed) }

          let(:user) { order_dist_1.distributor.owner }
          let(:'X-Spree-Token') do
            user.generate_api_key
            user.save
            user.spree_api_key
          end

          context "and there are no query parameters" do
            run_test! do |response|
              expect(response).to have_http_status(200)

              data = JSON.parse(response.body)
              orders = data["orders"]
              expect(orders.size).to eq 4
            end
          end

          context "and queried by distributor id" do
            let(:'q[distributor_id_eq]') { order_dist_2.distributor.id }

            before { order_dist_2.distributor.update owner: user }

            run_test! do |response|
              expect(response).to have_http_status(200)

              data = JSON.parse(response.body)
              orders = data["orders"]
              expect(orders.size).to eq 1
              expect(orders.first["id"]).to eq order_dist_2.id
            end
          end

          context "and queried within a date range" do
            let(:'q[completed_at_gt]') { Time.zone.today - 7.days - 1.second }
            let(:'q[completed_at_lt]') { Time.zone.today - 6.days }

            run_test! do |response|
              expect(response).to have_http_status(200)

              data = JSON.parse(response.body)
              orders = data["orders"]
              expect(orders.size).to eq 1
              expect(orders.first["id"]).to eq order_dist_1_complete.id
            end
          end

          context "and queried by complete state" do
            let(:'q[state_eq]') { "complete" }
            run_test! do |response|
              expect(response).to have_http_status(200)

              data = JSON.parse(response.body)
              orders = data["orders"]
              expect(orders.size).to eq 1
              expect(orders.first["id"]).to eq order_dist_1_complete.id
            end
          end

          context "and queried by credit_owed payment_state" do
            let(:'q[payment_state_eq]') { "credit_owed" }
            run_test! do |response|
              expect(response).to have_http_status(200)

              data = JSON.parse(response.body)
              orders = data["orders"]
              expect(orders.size).to eq 1
              expect(orders.first["id"]).to eq order_dist_1_credit_owed.id
            end
          end

          context "and queried by buyer email contains a specific string" do
            let(:'q[email_cont]') { order_dist_1.email.split("@").first }
            run_test! do |response|
              expect(response).to have_http_status(200)

              data = JSON.parse(response.body)
              orders = data["orders"]
              expect(orders.size).to eq 1
              expect(orders.first["id"]).to eq order_dist_1.id
            end
          end

          context "and queried by a specific order_cycle" do
            let(:'q[order_cycle_id_eq]') {
              order_dist_2.order_cycle.id
            }

            before { order_dist_2.distributor.update owner: user }

            run_test! do |response|
              expect(response).to have_http_status(200)

              data = JSON.parse(response.body)
              orders = data["orders"]
              expect(orders.size).to eq 1
              expect(orders.first["id"]).to eq order_dist_2.id
            end
          end

          context "and queried by cart state" do
            let!(:order_empty) {
              create(:order_with_line_items, line_items_count: 0)
            }

            let!(:order_not_empty) {
              create(:order_with_line_items, line_items_count: 1)
            }

            let!(:order_not_empty_no_address) {
              create(:order_with_line_items, line_items_count: 1, bill_address_id: nil,
                                             ship_address_id: nil)
            }

            let(:'q[state_eq]') { "cart" }

            run_test! do |response|
              data = JSON.parse(response.body)
              orders = data["orders"]
              expect(orders.size).to eq 3
            end
          end
        end
      end
    end
  end
end
