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
  let(:variant) { build(:base_variant, id: 10_001, unit_value: 1, sku: "AR", enterprise:) }
  let(:second_product) {
    create(
      :base_product,
      id: 90_001, name: "Pear", description: "Green",
      variants: [second_variant],
    )
  }
  let(:second_variant) { build(:base_variant, id: 10_002, unit_value: 1, sku: "PE", enterprise:) }

  before { login_as user }

  # The order factory builds line items and variants with auto-increment ids,
  # which would change swagger/dfc.yaml on every regeneration, so document them
  # with fixed ones.
  #
  # Offers and supplied products are built from the variant, so their ids come
  # from the same list.
  def normalise_ids(ofn_order, offset: 0)
    ofn_order.line_items.each_with_index do |line_item, index|
      number = offset + index + 1
      line_item_id = line_item.id
      variant_id = line_item.variant_id

      replace_in_docs(
        "OrderLines/#{line_item_id}" => "OrderLines/1000#{number}",
        "offers/#{variant_id}" => "offers/2000#{number}",
        "supplied_products/#{variant_id}" => "supplied_products/2000#{number}",
      )
    end
  end

  path "/api/dfc/enterprises/{enterprise_id}/orders/{order_id}" do
    parameter name: :enterprise_id, in: :path, type: :string

    get "Show Order" do
      produces "application/json"
      parameter name: :order_id, in: :path

      # A single line item for the variant of this spec. The factory would add
      # line items with randomly allocated variants, which the generated
      # documentation would then record with different ids on every run.
      let(:order) {
        product # a product with a fixed name and id, so that the response is stable
        variant.update! on_hand: 1
        create(:completed_order_with_totals, :with_line_item, id: 11_000,
                                                              line_items_count: 0,
                                                              distributor: enterprise, variant:)
      }

      response "200", "success" do
        let(:enterprise_id) { enterprise.id }
        let(:order_id) { order.id }

        run_test! {
          normalise_ids(order)

          expect(response.body).to include "dfc-b:Order", "orders/11000"
          line_item = order.line_items.first
          expect(response.body).to include "dfc-b:OrderLine", "OrderLines/#{line_item.id}"
          expect(response.body).to include "dfc-b:Offer", "offers/#{line_item.variant_id}",
                                           "dfc-b:offeredItem"
          expect(response.body).to include "dfc-b:SuppliedProduct",
                                           "supplied_products/#{line_item.variant_id}"
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

    put "Update Order" do
      produces "application/json"
      consumes "application/json"

      parameter name: :order_id, in: :path
      parameter name: :body, in: :body, schema: {
        example: Rails.root.join('spec/fixtures/files/fdc-update-backorder.json').read
      }

      let(:body) {
        Rails.root.join('spec/fixtures/files/fdc-update-backorder.json').read
      }

      let(:order) {
        variant.save
        variant.update! on_hand: 10
        create(:completed_order_with_totals, :with_line_item, id: 11_000,
                                                              distributor: enterprise, variant:)
      }

      response "200", "success" do
        let(:enterprise_id) { enterprise.id }
        let(:order_id) { order.id }

        run_test! {
          ofn_order = enterprise.distributed_orders.find(order.id)
          target_line = ofn_order.line_items.find_by!(variant_id: variant.id)
          expect(target_line.quantity).to eq 5
        }
      end

      response "200", "order completed" do
        let(:enterprise_id) { enterprise.id }
        let(:order_id) { order.id }
        let(:body) {
          json = JSON.parse(
            Rails.root.join('spec/fixtures/files/fdc-update-backorder.json').read
          )
          json["@graph"].find { |n|
            n["@type"] == "dfc-b:Order"
          }["dfc-b:hasOrderStatus"] = "dfc-v:Complete"
          json.to_json
        }

        run_test! {
          ofn_order = enterprise.distributed_orders.find(order.id)
          expect(ofn_order.completed_at).to be_present
        }
      end

      response "400", "bad request" do
        context "with empty request body" do
          let(:enterprise_id) { enterprise.id }
          let(:order_id) { order.id }
          let(:body) { nil }

          run_test! {
            expect(response).to have_http_status :bad_request
          }
        end
      end

      response "401", "unauthorized" do
        let(:enterprise_id) { enterprise.id }
        let(:order_id) { order.id }

        before { login_as nil }

        run_test! {
          expect(response).to have_http_status :unauthorized
        }
      end

      response "404", "not found" do
        context "without order" do
          let(:enterprise_id) { enterprise.id }
          let(:order_id) { "blah" }

          run_test! {
            expect(response).to have_http_status :not_found
          }
        end

        context "without enterprise" do
          let(:enterprise_id) { "blah" }
          let(:order_id) { order.id }

          run_test! {
            expect(response).to have_http_status :not_found
          }
        end

        context "with unrelated enterprise" do
          let(:enterprise_id) { create(:enterprise).id }
          let(:order_id) { order.id }

          run_test! {
            expect(response).to have_http_status :not_found
          }
        end
      end

      response "422", "unprocessable entity" do
        let(:enterprise_id) { enterprise.id }
        let(:order_id) { order.id }
        let(:body) {
          json = JSON.parse(
            Rails.root.join('spec/fixtures/files/fdc-update-backorder.json').read
          )
          offer = json["@graph"].find { |n| n["@type"] == "dfc-b:Offer" }
          offer["dfc-b:offeredItem"] =
            "http://test.host/api/dfc/enterprises/10000/supplied_products/99999"
          json.to_json
        }

        run_test! {
          expect(response.body).to include "Line items reference unknown products"
        }
      end
    end

    delete "Cancel Order" do
      parameter name: :order_id, in: :path, type: :string

      let(:order) {
        variant.save
        variant.update! on_hand: 1
        create(:completed_order_with_totals, :with_line_item, id: 11_000,
                                                              distributor: enterprise, variant:)
      }

      response "204", "no content" do
        let(:enterprise_id) { enterprise.id }
        let(:order_id) { order.id }

        run_test! {
          expect(order.reload.state).to eq "canceled"
        }
      end

      response "401", "unauthorized" do
        let(:enterprise_id) { enterprise.id }
        let(:order_id) { order.id }

        before { login_as nil }

        run_test! {
          expect(response).to have_http_status :unauthorized
        }
      end

      response "404", "not found" do
        context "without order" do
          let(:enterprise_id) { enterprise.id }
          let(:order_id) { "blah" }

          run_test! {
            expect(response).to have_http_status :not_found
          }
        end

        context "without enterprise" do
          let(:enterprise_id) { "blah" }
          let(:order_id) { order.id }

          run_test! {
            expect(response).to have_http_status :not_found
          }
        end

        context "with unrelated enterprise" do
          let(:enterprise_id) { create(:enterprise).id }
          let(:order_id) { order.id }

          run_test! {
            expect(response).to have_http_status :not_found
          }
        end
      end

      response "422", "unprocessable entity" do
        let(:enterprise_id) { enterprise.id }
        let(:order) { create(:order, id: 11_001, distributor: enterprise) }
        let(:order_id) { order.id }

        run_test! {
          expect(response).to have_http_status :unprocessable_entity
          expect(response.body).to include "Cannot cancel order"
        }
      end
    end
  end

  path "/api/dfc/enterprises/{enterprise_id}/orders" do
    parameter name: :enterprise_id, in: :path, type: :string

    get "List Orders" do
      description <<~MARKDOWN
        Lists the orders placed with this enterprise, with their lines in the same graph.
        Carts that nobody has placed yet are not listed.
      MARKDOWN
      produces "application/json"
      security [{ oidc_token: [] }]

      parameter name: :page, in: :query, type: :integer, required: false,
                description: "Page to return, starting at 1."
      parameter name: :per_page, in: :query, type: :integer, required: false,
                description: "Number of orders per page, between 1 and 100. Defaults to 25."
      parameter name: :updated_since, in: :query, type: :string, required: false,
                description: "Only return the orders updated at or after this ISO 8601 time."

      let(:Authorization) { nil }
      let(:page) { nil }
      let(:per_page) { nil }
      let(:updated_since) { nil }

      response "200", "success" do
        let(:enterprise_id) { enterprise.id }

        context "with two orders" do
          before do
            product
            second_product
            variant.update! on_hand: 10
            second_variant.update! on_hand: 10
            create(:completed_order_with_totals, :with_line_item, id: 11_000,
                                                                  line_items_count: 0,
                                                                  distributor: enterprise, variant:)
            create(:completed_order_with_totals, :with_line_item, id: 11_001,
                                                                  line_items_count: 0,
                                                                  distributor: enterprise,
                                                                  variant: second_variant)
          end

          run_test! do
            orders = enterprise.distributed_orders.order(:id)
            normalise_ids(orders.first)
            normalise_ids(orders.last, offset: orders.first.line_items.count)

            expect(response.body).to include "dfc-b:Order", "orders/11000", "orders/11001"
            line_urls = orders.map do |ofn_order|
              "orders/#{ofn_order.id}/OrderLines/#{ofn_order.line_items.first.id}"
            end
            expect(response.body).to include(*line_urls)
          end
        end

        context "without orders" do
          run_test! do
            expect(response.body).to be_empty
          end
        end
      end

      response "400", "bad request" do
        let(:enterprise_id) { enterprise.id }
        let(:updated_since) { "yesterday" }

        run_test!
      end

      response "401", "unauthorized" do
        let(:enterprise_id) { enterprise.id }

        before { login_as nil }

        run_test!
      end

      response "404", "not found" do
        context "without enterprise" do
          let(:enterprise_id) { "blah" }

          run_test!
        end

        context "with unrelated enterprise" do
          let(:enterprise_id) { create(:enterprise).id }

          run_test!
        end
      end
    end

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
          enterprise.customers.create!(user:, email: user.email)
          product
          variant.on_hand = 1
        end

        context "with line items" do
          let(:enterprise_id) { enterprise.id }

          run_test! {
            ofn_order = enterprise.distributed_orders.first

            # The id of the new order is allocated by the database:
            replace_in_docs("orders/#{ofn_order.id}" => "orders/10001")

            expect(enterprise.distributed_orders.count).to eq 1
            expect(ofn_order.created_by).to eq user
            expect(ofn_order.email).to eq "user@example.com"
            expect(ofn_order.customer.email).to eq user.email
            expect(ofn_order.state).to eq "complete"

            expect(ofn_order.line_items.count).to eq 1
            expect(ofn_order.line_items.first.variant).to eq variant
            expect(ofn_order.line_items.first.quantity).to eq 1

            expect(response.body).to include "dfc-b:Order"
            expect(response.body).to include "/api/dfc/enterprises/10000/orders/#{ofn_order.id}"

            # The client can then fetch the order from there:
            expect(response.headers["Location"])
              .to eq "http://test.host/api/dfc/enterprises/10000/orders/#{ofn_order.id}"
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

        context "variant not found" do
          run_test! {
            expect(enterprise.distributed_orders).to be_empty

            expect(response.body).to include "Line items reference unknown products"
          }
        end
      end
    end
  end
end
