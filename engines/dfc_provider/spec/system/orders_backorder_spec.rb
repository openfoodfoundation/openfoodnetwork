# frozen_string_literal: true

require_relative "../system_helper"

# Test the dfc/orders endpoint with the backorderer
#
# Confirms the requirement that two OFN instances can talk together (or the
# same instance talking to itself): a distributor places an order whose line
# items are linked to a supplier's supplied products, and a backorder is placed
# against the supplier's catalog through the DFC API.
RSpec.describe "Orders backorder integration" do
  include AuthorizationHelper

  let(:host) { Rails.application.default_url_options[:host] }

  # Supplier sells their product on OFN via DFC api
  let(:supplier_owner) { create(:oidc_user, id: 12_345) }
  let(:supplier) {
    create(:distributor_enterprise, id: 10_000, name: "Fred's Farm", owner: supplier_owner)
  }
  let(:variant) {
    build(:base_variant, id: 10_001, unit_value: 1, sku: "SUP", enterprise: supplier)
  }
  let(:semantic_id) {
    "http://#{host}/api/dfc/enterprises/#{supplier.id}/supplied_products/#{variant.id}"
  }
  let!(:supplier_order_cycle) {
    create(:simple_order_cycle, distributors: [supplier], variants: [variant])
  }

  # Distributor has imported a copy of the product and is selling it
  # The distributor must be authorised with the email address of the supplier owner.
  # Because they are on the same OFN instance in this test, they must be the same user.
  let(:distributor_owner) { supplier_owner }
  let(:distributor) {
    create(:distributor_enterprise, id: 11_000, owner: distributor_owner, name: "Shane's Shop")
  }
  let(:distributor_variant) {
    create(:variant, id: 11_001, unit_value: 1, sku: "DIST", on_hand: 10,
                     enterprise: distributor).tap { |v|
      v.semantic_links.create(semantic_id:) # variant is linked to supplier variant
      v.on_demand = false
    }
  }
  let(:distributor_order_cycle) {
    create(:simple_order_cycle, distributors: [distributor], variants: [distributor_variant])
  }

  # Customer orders the distributed product
  let(:distributor_order) {
    create(:order_with_totals_and_distribution,
           variant: distributor_variant,
           distributor:, order_cycle: distributor_order_cycle)
  }

  before {
    # For this test, OFN is talking to itself. We currently don't allow that IRL.
    allow(PrivateAddressCheck).to receive(:private_address?).and_return(false)

    # Pretend that user has authenticated with OIDC
    distributor_owner.oidc_account.update!(token: allow_token_for(email: distributor_owner.email))

    variant.on_hand = 100
  }

  describe "BackorderJob" do
    let(:supplier_order) { supplier.distributed_orders.first }

    it "creates an order for the source variant" do
      # For debugging you can check log/test.log, eg:
      # echo "" > log/test.log; tail -f log/test.log | egrep "(Started|Completed)"

      expect {
        # BackorderJob.perform_now(order) # Cannot perform whole job as it gets stuck on record lock
        BackorderJob.new.place_backorder(distributor_order)
      }.to change { supplier.distributed_orders.count }.by(1)

      expect(supplier_order.created_by).to eq distributor_owner
      expect(supplier_order.user).to eq distributor_owner
      expect(supplier_order.email).to eq distributor_owner.email
      expect(supplier_order.state).to eq "complete"

      expect(supplier_order.line_items.count).to eq 1
      expect(supplier_order.line_items.first.variant).to eq variant
      expect(supplier_order.line_items.first.quantity).to eq 1
    end

    # Blocked by a DFC connector v1 bug, not by the orders endpoint: importing
    # an order whose `dfc-b:orderedBy` is a bare URI reference turns that
    # property into a parsed-URI Hash, which then can't be exported again.
    #
    #   order = DfcIo.import('{"@context":"https://www.datafoodconsortium.org",
    #     "@graph":[{"@id":"http://test.host/orders/5","@type":"dfc-b:Order",
    #     "dfc-b:orderedBy":"http://test.host/enterprises/1"}]}')
    #   order.client
    #   # => {scheme: "http", authority: "test.host", ...}
    #   DfcIo.export(order)
    #   # => RuntimeError: The type of the property 'dfc-b:orderedBy' is 'Hash'
    #   #    but a primitive, a SemanticObject or an Array is required.
    #
    # CompleteBackorderJob re-exports the order it fetched, so it fails there.
    xit "synchronises quantities at the end of the order cycle" do
      BackorderJob.new.place_backorder(distributor_order)

      supplier_line_item = supplier_order.line_items.first
      distributor_order.line_items.first.update! quantity: 2

      expect {
        perform_enqueued_jobs(only: CompleteBackorderJob)
        supplier_line_item.reload
      }.to change { supplier_line_item.quantity }.from(1).to(2)
    end
  end
end
