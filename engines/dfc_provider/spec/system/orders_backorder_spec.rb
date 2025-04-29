# frozen_string_literal: true

require_relative "../system_helper"

# Test the dfc/orders endpoint with the backorderer
RSpec.describe "Orders backorder integration" do
  include AuthorizationHelper

  let(:host) { Rails.application.default_url_options[:host] }

  # Supplier sells their product on OFN via DFC api
  let(:supplier_owner) { create(:oidc_user, id: 12_345) }
  let(:supplier) {
    create(:distributor_enterprise, id: 10_000, name: "Fred's Farm", owner: supplier_owner)
  }
  let(:variant) { build(:base_variant, id: 10_001, unit_value: 1, sku: "SUP", supplier:, ) }
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
                     supplier: distributor).tap { |v|
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
           :with_line_item,
           variant: distributor_variant,
           distributor:, order_cycle: distributor_order_cycle)
  }

  before {
    # For this test, OFN is talking to itself. We currently don't allow that IRL.
    allow(PrivateAddressCheck).to receive(:private_address?).and_return(false)

    # Pretend that user has authenticated with OIDC
    distributor_owner.oidc_account.update!(token: allow_token_for(email: distributor_owner.email))

    variant.on_hand = 1
  }

  xit "debugging: accesses the webserver" do
    # try accessing the supplier's catalog
    url = "http://#{host}/api/dfc/enterprises/#{supplier.id}/catalog_items"

    DfcRequest.new(distributor_owner).call(url)
    result = DfcRequest.new(distributor_owner).call(url) # make a second http request, also works.
    DfcIo.import(result)

    puts "\nRequest: #{url}\n"
    puts "Response includes:"
    puts result.scan(/[^"]*10001[^"]*/)
    # http://127.0.0.1:56286/api/dfc/enterprises/10000/catalog_items/10001
    # http://127.0.0.1:56286/api/dfc/enterprises/10000/supplied_products/10001
  end

  describe "BackorderJob" do
    it "creates an order for the source variant" do
      # For debugging you can check log/test.log, eg:
      # echo "" > log/test.log; tail -f log/test.log | egrep "(Started|Completed)"

      expect {
        # BackorderJob.perform_now(order) # Cannot perform whole job as it gets stuck on record lock
        BackorderJob.new.place_backorder(distributor_order)
      }.to change { supplier.distributed_orders.count }.by(1)

      supplier_order = supplier.distributed_orders.first
      expect(supplier_order.created_by).to eq distributor_owner
      expect(supplier_order.user).to eq distributor_owner
      expect(supplier_order.email).to eq distributor_owner.email
      expect(supplier_order.state).to eq "complete"

      expect(supplier_order.line_items.count).to eq 1
      expect(supplier_order.line_items.first.variant).to eq variant
      expect(supplier_order.line_items.first.quantity).to eq 1

      # At end of order cycle, the backorder should be synchronised.
      distributor_order.line_items.first.update! quantity: 2
      supplier_line_item = supplier_order.line_items.first

      expect {
        # backorder_url = "http://#{host}/api/dfc/enterprises/#{supplier.id}/orders/#{supplier.distributed_orders.first.id}" # aint no route for this
        # CompleteBackorderJob.perform_now(distributor_owner, distributor, distributor_order_cycle, backorder_url)
        perform_enqueued_jobs(only: CompleteBackorderJob)
        supplier_line_item.reload
      }.to change { supplier_line_item.quantity }.to(2)

    rescue Faraday::UnprocessableEntityError => e
      # Output error message for convenient debugging
      expect(e.response[:body]).to be_blank
    end
  end
end
