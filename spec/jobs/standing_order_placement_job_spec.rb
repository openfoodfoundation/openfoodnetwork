require 'spec_helper'

describe StandingOrderPlacementJob do
  let(:shop) { create(:distributor_enterprise) }
  let(:order_cycle1) { create(:simple_order_cycle, coordinator: shop) }
  let(:order_cycle2) { create(:simple_order_cycle, coordinator: shop) }
  let(:schedule1) { create(:schedule, order_cycles: [order_cycle1]) }
  let(:schedule2) { create(:schedule, order_cycles: [order_cycle1, order_cycle2]) }
  let(:standing_order1) { create(:standing_order_with_items, shop: shop, schedule: schedule1) }
  let(:standing_order2) { create(:standing_order_with_items, shop: shop, schedule: schedule2) }

  let!(:job) { StandingOrderPlacementJob.new(order_cycle1) }

  describe "finding standing_order orders for the specified order cycle" do
    let(:order1) { create(:order, order_cycle: order_cycle1, completed_at: 5.minutes.ago) } # Complete + Linked + OC Matches
    let(:order2) { create(:order, order_cycle: order_cycle1) } # Incomplete + Linked + OC Matches
    let(:order3) { create(:order, order_cycle: order_cycle1) } # Incomplete + Not-Linked + OC Matches
    let(:order4) { create(:order, order_cycle: order_cycle2) } # Incomplete + Linked + OC Mismatch

    before do
      standing_order1.orders = [order1,order2]
      standing_order2.orders = [order4]
    end

    it "only returns incomplete orders in the relevant order cycle that are linked to a standing order" do
      orders = job.send(:orders)
      expect(orders).to include order2
      expect(orders).to_not include order1, order3, order4
    end
  end
end
