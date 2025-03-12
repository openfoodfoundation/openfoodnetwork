# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "Orders swagger", swagger_doc: "dfc.yaml" do
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
    end
  end
end

RSpec.describe "Orders integration" do
  let(:user) { create(:oidc_user, id: 12_345) }
  let(:supplier) {
    create(
      :distributor_enterprise, # supplier sells their products on an OFN instance
      id: 10_000, owner: user, name: "Fred's Farm",
      address: build(:address, id: 40_000),
    )
  }
  let(:product) {
    create(
      :base_product,
      id: 90_000, name: "Apple", description: "Red",
      variants: [variant],
      primary_taxon: non_local_vegetable
    )
  }
  let(:non_local_vegetable) {
    build(
      :taxon,
      name: "Non Local Vegetable",
      dfc_id: "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#non-local-vegetable"
    )
  }
  let(:variant) { build(:base_variant, id: 10_001, unit_value: 1, sku: "AR", supplier:) }

  let(:distributor) {
    create(
      :distributor_enterprise, # distributor has imported supplier's product to create a copy of it
      id: 20_000, owner: user, name: "Shane's Shop",
      address: build(:address, id: 41_000),
    )
  }

  before {
    login_as user
    product

    # TODO: create distributor product with semantic link to supplier product
  }

  describe BackorderJob do
    it "creates a product" do
      # post(enterprise_orders_path(supplier.id))
      pending "finish spec"
      # TODO: make a distributor order, and flush BackorderJob

      # A backorder to the supplier has been created
      expect(supplier.distributed_orders.count).to eq 1
    end
  end
end
