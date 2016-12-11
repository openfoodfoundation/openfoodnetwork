require 'spec_helper'

describe StandingOrderConfirmJob do
  let(:shop) { create(:distributor_enterprise) }
  let(:order_cycle1) { create(:simple_order_cycle, coordinator: shop) }
  let(:order_cycle2) { create(:simple_order_cycle, coordinator: shop) }
  let(:schedule1) { create(:schedule, order_cycles: [order_cycle1, order_cycle2]) }
  let(:standing_order1) { create(:standing_order_with_items, shop: shop, schedule: schedule1) }
  let!(:job) { StandingOrderConfirmJob.new(order_cycle1) }

  describe "finding standing_order orders for the specified order cycle" do
    let(:order1) { create(:order) } # Incomplete + Linked + OC Matches
    let(:order2) { create(:order, completed_at: 5.minutes.ago) } # Complete + Not-Linked + OC Matches
    let(:order3) { create(:order, completed_at: 5.minutes.ago) } # Complete + Linked + OC Mismatch
    let(:order4) { create(:order, completed_at: 5.minutes.ago) } # Complete + Linked + OC Matches + Cancelled
    let(:order5) { create(:order, completed_at: 5.minutes.ago) } # Complete + Linked + OC Matches
    let!(:proxy_order1) { create(:proxy_order, order_cycle: order_cycle1, standing_order: standing_order1, order: order1) }
    let!(:proxy_order3) { create(:proxy_order, order_cycle: order_cycle2, standing_order: standing_order1, order: order3) }
    let!(:proxy_order4) { create(:proxy_order, order_cycle: order_cycle1, standing_order: standing_order1, order: order4, canceled_at: 1.minute.ago) }
    let!(:proxy_order5) { create(:proxy_order, order_cycle: order_cycle1, standing_order: standing_order1, order: order5) }

    it "only returns incomplete orders in the relevant order cycle that are linked to a standing order" do
      orders = job.send(:orders)
      expect(orders).to include order5
      expect(orders).to_not include order1, order2, order3, order4
    end
  end

  describe "processing an order" do
    let(:order) { standing_order1.orders.first }

    before do
      form = StandingOrderForm.new(standing_order1)
      form.send(:initialise_proxy_orders!)
      while !order.completed? do break unless order.next! end
      allow(job).to receive(:send_confirm_email).and_call_original
      Spree::MailMethod.create!(
        environment: Rails.env,
        preferred_mails_from: 'spree@example.com'
      )
    end

    it "sends only a standing order confirm email, no regular confirmation emails" do
      ActionMailer::Base.deliveries.clear
      expect{job.send(:process, order)}.to_not enqueue_job ConfirmOrderJob
      expect(job).to have_received(:send_confirm_email).with(order).once
      expect(ActionMailer::Base.deliveries.count).to be 1
    end
  end
end
