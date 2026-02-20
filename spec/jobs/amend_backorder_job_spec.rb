# frozen_string_literal: true

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

  describe ".schedule_bulk_update_for" do
    let(:order_same_oc) {
      create(
        :completed_order_with_totals,
        distributor: order.distributor,
        order_cycle: order.order_cycle,
      )
    }
    let(:order_other_oc) { create(:completed_order_with_totals) }

    it "enqueues only one job per backorder" do
      expect {
        AmendBackorderJob.schedule_bulk_update_for([order, order_same_oc])
      }.to enqueue_job(AmendBackorderJob).exactly(:once)
    end

    it "enqueues a job for each backorder" do
      expect {
        AmendBackorderJob.schedule_bulk_update_for([order, order_other_oc])
      }.to enqueue_job(AmendBackorderJob).exactly(:twice)
    end
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

      # We increase quantities which should be reflected in the backorder:
      beans.on_hand = -1
      chia_item.quantity += 3
      chia_item.save!

      expect { subject.amend_backorder(order) }
        .to change { beans.on_hand }.from(-1).to(11)
        .and change { backorder.lines[0].quantity }.from(1).to(2)
        .and change { backorder.lines[1].quantity }.from(5).to(8)

      # We cancel the only order.
      expect { order.cancel! }
        .to change { beans.reload.on_hand }.from(11).to(17)
        .and change { chia_seed.reload.on_hand }.from(4).to(12)

      # But we decreased the stock of beans outside of orders above.
      # So only the chia seeds are cancelled. The beans still need replenishing.
      expect { subject.amend_backorder(order) }
        .to change { backorder.lines.count }.from(2).to(1)
        .and change { beans.reload.on_hand }.by(-12)
    end

    it "creates a new order" do
      stub_request(:get, catalog_url).to_return(body: catalog_json)

      # Record the placed backorder:
      backorder = nil
      allow_any_instance_of(FdcBackorderer).to receive(:find_order) do |*_args|
        backorder
      end
      allow_any_instance_of(FdcBackorderer).to receive(:send_order) do |*args|
        backorder = args[1]
      end

      # Call amending before a backorder has been placed.
      expect { subject.amend_backorder(order) }
        .to change { backorder.present? }
        .to(true)

      # We ordered a case of 12 cans: -3 + 12 = 9
      expect(beans.on_hand).to eq 9

      # Stock controlled items don't change stock in backorder:
      expect(chia_seed.on_hand).to eq 7

      expect(backorder.lines[0].quantity).to eq 1 # beans
      expect(backorder.lines[1].quantity).to eq 5 # chia
    end
  end
end
