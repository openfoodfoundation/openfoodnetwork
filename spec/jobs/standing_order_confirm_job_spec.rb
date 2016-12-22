require 'spec_helper'

describe StandingOrderConfirmJob do
  let(:shop) { create(:distributor_enterprise) }
  let(:order_cycle1) { create(:simple_order_cycle, coordinator: shop) }
  let(:order_cycle2) { create(:simple_order_cycle, coordinator: shop) }
  let(:schedule1) { create(:schedule, order_cycles: [order_cycle1, order_cycle2]) }
  let(:standing_order1) { create(:standing_order, shop: shop, schedule: schedule1, with_items: true) }

  let!(:job) { StandingOrderConfirmJob.new(order_cycle1) }

  describe "processing an order" do
    let(:proxy_order) { create(:proxy_order, standing_order: standing_order1) }
    let(:order) { proxy_order.initialise_order! }

    before do
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
