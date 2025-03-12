# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "Orders", swagger_doc: "dfc.yaml" do
  let(:user) { create(:oidc_user, id: 12_345) }
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

  path "/api/dfc/enterprises/{enterprise_id}/orders" do
    parameter name: :enterprise_id, in: :path, type: :string

    post "Create Order" do
      response "201", "created" do
        before { product }

        context "with given enterprise id" do
          let(:enterprise_id) { enterprise.id }

          run_test! {
            expect(enterprise.distributed_orders.count).to eq 1
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
    end
  end
end
