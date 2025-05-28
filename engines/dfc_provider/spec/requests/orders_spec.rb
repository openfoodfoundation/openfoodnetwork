# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "Orders", swagger_doc: "dfc.yaml" do
  let(:user) { create(:oidc_user, id: 12_345, email: "user@example.com") }
  let(:enterprise) {
    create(
      :distributor_enterprise,
      id: 10_000, owner: user, name: "Fred's Farm", description: "Beautiful",
      address: build(:address, id: 40_000),
    )
  }
  let(:product) {
    create(
      :base_product,
      id: 90_000, name: "Apple", description: "Red",
      variants: [variant],
    )
  }
  let(:variant) { build(:base_variant, id: 10_001, unit_value: 1, sku: "AR", supplier: enterprise) }

  before { login_as user }

  path "/api/dfc/enterprises/{enterprise_id}/orders/{order_id}" do
    parameter name: :enterprise_id, in: :path, type: :string

    get "Show Order" do
      produces "application/json"
      parameter name: :order_id, in: :path

      let(:order) {
        variant.save
        variant.update! on_hand: 1
        create(:completed_order_with_totals, :with_line_item, id: 11_000,
                                                              distributor: enterprise, variant:)
      }

      response "200", "success" do
        let(:enterprise_id) { enterprise.id }
        let(:order_id) { order.id }

        run_test! {
          expect(response.body).to include "dfc-b:Order",       "orders/11000"
          expect(response.body).to include "dfc-b:OrderLine",   "OrderLines/"
          expect(response.body).to include "dfc-b:Offer",       "offers/", "dfc-b:offeredItem"
          expect(response.body).to include "dfc-b:SuppliedProduct", "supplied_products/10001"
        }
      end

      response "401", "unauthorized" do
        let(:enterprise_id) { enterprise.id }
        let(:order_id) { order.id }

        before { login_as nil }

        run_test! {
          expect(response.body).to be_empty
        }
      end

      response "404", "not found" do
        context "without order" do
          let(:enterprise_id) { enterprise.id }
          let(:order_id) { "blah" }

          run_test! {
            expect(response.body).to be_empty
          }
        end

        context "without enterprise" do
          let(:enterprise_id) { "blah" }
          let(:order_id) { order.id }

          run_test! {
            expect(response.body).to be_empty
          }
        end

        context "with unrelated enterprise" do
          let(:enterprise_id) { create(:enterprise).id }
          let(:order_id) { order.id }

          run_test! {
            expect(response.body).to be_empty
          }
        end
      end
    end
  end

  path "/api/dfc/enterprises/{enterprise_id}/orders" do
    parameter name: :enterprise_id, in: :path, type: :string

    post "Create Order" do
      produces "application/json"
      consumes "application/json"

      parameter name: :body, in: :body, schema: {
        # To update fixture, add this to orders_controller.rb#create:
        #   File.write(Rails.root.join('spec/fixtures/files/fdc-send-backorder.json'),
        #              JSON.pretty_generate(JSON.parse(request.body.read)))
        # Then execute:
        #   rspec engines/dfc_provider/spec/system/orders_backorder_spec.rb
        example: Rails.root.join('spec/fixtures/files/fdc-send-backorder.json').read
      }

      let(:body) { |example|
        example.metadata[:operation][:parameters].first[:schema][:example]
      }

      response "201", "created" do
        before do
          # User may be an existing customer of the enterprise
          enterprise.customers.create!(user:, email: user.email)
          product
          variant.on_hand = 1
        end

        context "with line items" do
          let(:enterprise_id) { enterprise.id }

          run_test! {
            expect(enterprise.distributed_orders.count).to eq 1
            ofn_order = enterprise.distributed_orders.first
            expect(ofn_order.created_by).to eq user
            expect(ofn_order.email).to eq "user@example.com"
            expect(ofn_order.customer.email).to eq user.email
            expect(ofn_order.state).to eq "complete"

            expect(ofn_order.line_items.count).to eq 1
            expect(ofn_order.line_items.first.variant).to eq variant
            expect(ofn_order.line_items.first.quantity).to eq 1

            # Insert static value to keep documentation deterministic:
            response.body.gsub!(
              "orders/#{ofn_order.id}",
              "orders/10001"
            )

            expect(response.body).to include "dfc-b:Order"
            expect(response.body).to include "/api/dfc/enterprises/10000/orders/10001"
          }
        end
      end

      response "400", "bad request" do
        context "with empty request body" do
          let(:enterprise_id) { enterprise.id }
          let(:body) { nil }

          run_test! {
            expect(enterprise.distributed_orders).to be_empty
          }
        end
      end

      response "401", "unauthorized" do
        let(:enterprise_id) { enterprise.id }

        before { login_as nil }

        run_test! {
          expect(enterprise.distributed_orders).to be_empty
        }
      end

      response "404", "not found" do
        context "without enterprises" do
          let(:enterprise_id) { "blah" }

          run_test! {
            expect(enterprise.distributed_orders).to be_empty
          }
        end

        context "with unrelated enterprise" do
          let(:enterprise_id) { create(:enterprise).id }

          run_test! {
            expect(enterprise.distributed_orders).to be_empty
          }
        end
      end

      response "422", "unprocessable entity" do
        let(:enterprise_id) { enterprise.id }

        context "with invalid order value" do
          run_test! {
            pending "haven't got a way to submit invalid values yet.."
            expect(enterprise.distributed_orders).to be_empty
          }
        end

        context "variant not found" do
          run_test! {
            expect(enterprise.distributed_orders.first.line_items).to be_empty

            expect(response.body).to include "Line items variant must exist"
          }
        end
      end
    end
  end
end
