# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AmendBackorderJob do
  let(:order) { create(:completed_order_with_totals) }
  let(:distributor) { order.distributor }
  let(:beans) { beans_item.variant }
  let(:beans_item) { order.line_items[0] }
  let(:chia_seed) { chia_item.variant }
  let(:chia_item) { order.line_items[1] }
  let(:user) { order.distributor.owner }
  let(:catalog_json) { file_fixture("fdc-catalog.json").read }
  let(:catalog_url) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts"
  }
  let(:product_link) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635"
  }
  let(:chia_seed_wholesale_link) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519468433715"
  }

  before do
    # This ensures that callbacks adjust stock correctly.
    # See: https://github.com/openfoodfoundation/openfoodnetwork/pull/12938
    order.reload

    user.oidc_account = build(:testdfc_account)

    beans.semantic_links << SemanticLink.new(
      semantic_id: product_link
    )
    chia_seed.semantic_links << SemanticLink.new(
      semantic_id: chia_seed_wholesale_link
    )
    order.order_cycle = create(
      :simple_order_cycle,
      distributors: [distributor],
      variants: order.variants,
    )
    order.save!

    beans.on_demand = true
    beans_item.update!(quantity: 6)
    beans.on_hand = -3

    chia_item.update!(quantity: 5)
    chia_seed.on_demand = false
    chia_seed.on_hand = 7
  end

  describe "#amend_backorder" do
    it "updates an order" do
      stub_request(:get, catalog_url).to_return(body: catalog_json)

      # Record the placed backorder:
      backorder = nil
      allow_any_instance_of(FdcBackorderer).to receive(:find_order) do |*_args|
        backorder
      end
      allow_any_instance_of(FdcBackorderer).to receive(:find_open_order) do |*_args|
        backorder
      end
      allow_any_instance_of(FdcBackorderer).to receive(:send_order) do |*args|
        backorder = args[1]
      end

      BackorderJob.new.place_backorder(order)

      # We ordered a case of 12 cans: -3 + 12 = 9
      expect(beans.on_hand).to eq 9

      # Stock controlled items don't change stock in backorder:
      expect(chia_seed.on_hand).to eq 7

      expect(backorder.lines[0].quantity).to eq 1 # beans
      expect(backorder.lines[1].quantity).to eq 5 # chia

      # Without any change, the backorder shouldn't get changed either:
      subject.amend_backorder(order)

      # Same as before:
      expect(beans.on_hand).to eq 9
      expect(chia_seed.on_hand).to eq 7
      expect(backorder.lines[0].quantity).to eq 1 # beans
      expect(backorder.lines[1].quantity).to eq 5 # chia

      # We cancel the only order and that should reduce the order lines to 0.
      expect { order.cancel! }
        .to change { beans.reload.on_hand }.from(9).to(15)
        .and change { chia_seed.reload.on_hand }.from(7).to(12)

      expect { subject.amend_backorder(order) }
        .to change { backorder.lines.count }.from(2).to(0)
    end
  end
end
