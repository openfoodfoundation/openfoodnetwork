# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "SaleSessions", swagger_doc: "dfc.yaml" do
  let(:Accept) { "application/json" }
  let(:Authorization) { nil }
  let(:user) { create(:oidc_user, id: 12_345) }
  let(:hub) {
    create(:distributor_enterprise, id: 10_000, owner: user, name: "Fred's Farm",
                                    address: build(:address, id: 40_000))
  }
  let(:producer) { create(:supplier_enterprise, id: 10_001, name: "Joe's Farm") }
  let(:coordinator) { create(:distributor_enterprise, id: 10_002, name: "Coordinator") }
  let!(:product) {
    create(:base_product, id: 90_000, name: "Apple", description: "Red", variants: [variant])
  }
  let(:variant) {
    build(:base_variant, id: 20_001, price: 10, unit_value: 1, sku: "AR", enterprise: producer)
  }

  # The documentation records the dates of the cycle and the price that the
  # fees of the cycle make, so the clock and the data are fixed here.
  before { travel_to(Time.zone.parse("2026-11-25 09:00")) }

  let!(:order_cycle) {
    create(:simple_order_cycle, id: 40_000, coordinator:,
                                orders_open_at: Time.zone.parse("2026-11-20 09:00"),
                                orders_close_at: Time.zone.parse("2026-11-30 18:00"))
  }
  let!(:incoming_exchange) {
    create(:exchange, order_cycle:, sender: producer, receiver: coordinator, incoming: true,
                      enterprise_fees: [
                        create(:enterprise_fee, :per_item, enterprise: producer, amount: 1.5),
                      ],
                      variants: [variant])
  }
  let!(:outgoing_exchange) {
    create(:exchange, order_cycle:, sender: coordinator, receiver: hub, incoming: false,
                      variants: [variant])
  }

  before do
    variant.update!(on_hand: 5)
    login_as user
  end

  path "/api/dfc/enterprises/{enterprise_id}/sale_sessions" do
    parameter name: :enterprise_id, in: :path, type: :string

    get "List SaleSessions" do
      produces "application/json"
      security [{ oidc_token: [] }]

      response "200", "success" do
        let(:enterprise_id) { 10_000 }

        run_test! do
          expect(response.body).to include "dfc-b:SaleSession", "sale_sessions/40000"
          expect(response.body).to include "sale_sessions/40000/offers/20001"
          expect(response.body).to include "dfc-b:hasPrice"
        end
      end

      response "401", "unauthorized" do
        context "as platform user" do
          include_context "authenticated as platform"

          let(:enterprise_id) { 10_000 }

          before {
            # It can see the enterprise but not its products.
            DfcPermission.create!(
              user:, enterprise_id:,
              scope: "ReadEnterprise", grantee: "cqcm-dev",
            )
          }

          run_test!
        end

        context "without authorisation" do
          let(:enterprise_id) { 10_000 }

          before { login_as nil }

          run_test!
        end
      end

      response "404", "not found" do
        context "with unrelated enterprise" do
          let(:enterprise_id) { create(:enterprise).id }

          run_test!
        end

        context "as a user without enterprises" do
          let(:enterprise_id) { "default" }

          before { login_as create(:user) }

          run_test!
        end
      end
    end
  end

  path "/api/dfc/enterprises/{enterprise_id}/sale_sessions/{id}" do
    parameter name: :enterprise_id, in: :path, type: :string
    parameter name: :id, in: :path, type: :string

    get "Show SaleSession" do
      produces "application/json"
      security [{ oidc_token: [] }]

      response "200", "success" do
        let(:enterprise_id) { 10_000 }
        let(:id) { order_cycle.id }

        run_test! do
          expect(response.body).to include "dfc-b:SaleSession", "sale_sessions/40000"
          expect(response.body).to include "dfc-b:beginDate", "dfc-b:lists"
        end
      end

      response "401", "unauthorized" do
        let(:enterprise_id) { 10_000 }
        let(:id) { order_cycle.id }

        before { login_as nil }

        run_test!
      end

      response "404", "not found" do
        context "for a cycle that this enterprise doesn't distribute" do
          let(:enterprise_id) { 10_000 }
          let(:id) { create(:simple_order_cycle, id: 40_001, coordinator:).id }

          run_test!
        end

        context "with unrelated enterprise" do
          let(:enterprise_id) { create(:enterprise).id }
          let(:id) { order_cycle.id }

          run_test!
        end
      end
    end
  end
end
