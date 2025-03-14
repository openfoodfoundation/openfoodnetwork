# frozen_string_literal: true

require_relative "../system_helper"

# Test the dfc/orders endpoint with the backorderer
RSpec.describe "Orders backorder integration" do
  include AuthorizationHelper

  # TODO: set up user authorisation
  it "PoC: accesses the webserver" do
    allow(PrivateAddressCheck).to receive(:private_address?).and_return(false) # we currently don't allow OFN to connect to itself IRL
    host = Rails.application.default_url_options[:host]
    url = "http://#{host}/api/dfc/enterprises/#{supplier.id}/catalog_items" # try accessing the supplier's catalog
    user = distributor_owner
    user.oidc_account.update!(token: allow_token_for(email: user.email))

    result = DfcRequest.new(user).call(url)
    object =  DfcIo.import(result)
    binding.pry
    # variant:
    # semanticId="http://test.host/api/dfc/enterprises/11000/supplied_products/11001"
    # semanticId="http://test.host/api/dfc/enterprises/11000/catalog_items/11001"
  end

  host = Rails.application.default_url_options[:host]

  # Supplier sells their product on OFN via DFC api
  let(:supplier) { create(:distributor_enterprise, id: 10_000, name: "Fred's Farm") }
  let(:variant) { build(:base_variant, id: 10_001, unit_value: 1, sku: "AR", supplier:, ) }
  let(:semantic_id) {
    "http://#{host}/api/dfc/enterprises/#{supplier.id}/supplied_products/#{variant.id}"
  }

  # Distributor has imported a copy of the product and is selling it
  let(:distributor_owner) { create(:oidc_user, id: 12_345) }
  let(:distributor) {
    create(:distributor_enterprise, id: 11_000, owner: distributor_owner, name: "Shane's Shop")
  }
  let(:distributor_variant) {
    build(:variant, id: 11_001, unit_value: 1, sku: "AR", on_hand: 10, supplier: distributor)
  }
  let(:order_cycle) {
    create(:simple_order_cycle, distributors: [distributor], variants: [variant])
  }

  # Customer has ordered the distributed product
  let(:order) {
    create(:order_with_totals_and_distribution, :with_line_item, variant: distributor_variant, distributor:, order_cycle:)
  } #todo

  before {
    distributor_variant.semantic_links.build semantic_id:
    distributor_variant.save
    distributor_variant.on_hand = 10
    distributor_variant.on_demand = true

  }

  describe "BackorderJob" do
    it "creates an order for the source variant" do
      BackorderJob.perform_now(order)

      # A backorder to the supplier has been created
      expect(supplier.distributed_orders.count).to eq 1
      # todo: check order details are correct
    end
  end
end
