# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BackorderJob do
  let(:order) { create(:completed_order_with_totals) }
  let(:beans) { order.line_items.first.variant }
  let(:chia_seed) { chia_item.variant }
  let(:chia_item) { order.line_items.second }
  let(:user) { order.distributor.owner }
  let(:product_link) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635"
  }
  let(:chia_seed_wholesale_link) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519468433715"
  }

  before do
    user.oidc_account = OidcAccount.new(
      uid: "testdfc@protonmail.com",
      refresh_token: ENV.fetch("OPENID_REFRESH_TOKEN"),
      updated_at: 1.day.ago,
    )
  end

  describe ".check_stock" do
    it "ignores products without semantic link" do
      expect {
        BackorderJob.check_stock(order)
      }.not_to enqueue_job(BackorderJob)
    end

    it "enqueues backorder" do
      beans.semantic_links << SemanticLink.new(
        semantic_id: product_link
      )

      expect {
        BackorderJob.check_stock(order)
      }.to enqueue_job(BackorderJob).with(order)
    end

    it "reports errors" do
      expect(Bugsnag).to receive(:notify).and_call_original

      expect {
        BackorderJob.check_stock(nil)
      }.not_to raise_error
    end
  end

  describe "#peform" do
    it "notifies owner of errors" do
      incorrect_order = create(:order)
      expect {
        subject.perform(incorrect_order)
      }.to enqueue_mail(BackorderMailer, :backorder_failed)
        .and raise_error(NoMethodError)
    end
  end

  describe "#place_backorder" do
    it "places an order", vcr: true do
      order.order_cycle = create(
        :simple_order_cycle,
        distributors: [order.distributor],
        variants: [beans],
      )
      completion_time = order.order_cycle.orders_close_at + 1.minute
      beans.on_demand = true
      beans.on_hand = -3
      beans.semantic_links << SemanticLink.new(
        semantic_id: product_link
      )

      chia_item.quantity = 5
      chia_seed.on_demand = false
      chia_seed.on_hand = 7
      chia_seed.semantic_links << SemanticLink.new(
        semantic_id: chia_seed_wholesale_link
      )

      # Record the placed backorder:
      backorder = nil
      allow_any_instance_of(FdcBackorderer).to receive(:send_order)
        .and_wrap_original do |original_method, *args, &_block|
        backorder = args[0]
        original_method.call(*args)
      end

      expect {
        subject.place_backorder(order)
      }.to enqueue_job(CompleteBackorderJob).at(completion_time)

      # We ordered a case of 12 cans: -3 + 12 = 9
      expect(beans.on_hand).to eq 9

      # Stock controlled items don't change stock in backorder:
      expect(chia_seed.on_hand).to eq 7

      expect(backorder.lines[0].quantity).to eq 1 # beans
      expect(backorder.lines[1].quantity).to eq 5 # chia

      # Clean up after ourselves:
      perform_enqueued_jobs(only: CompleteBackorderJob)
    end

    it "succeeds when no work to be done" do
      # The database can change before the job is run. So maybe there's nothing
      # to do.
      expect {
        subject.place_backorder(order)
      }.not_to raise_error
    end
  end

  describe "#place_order" do
    it "schedules backorder completion for specific enterprises" do
      order.order_cycle = create(
        :simple_order_cycle,
        id: 1,
        orders_close_at: Date.tomorrow.noon,
      )
      completion_time = Date.tomorrow.noon + 4.hours

      exchange = order.order_cycle.exchanges.create!(
        incoming: false,
        sender: order.order_cycle.coordinator,
        receiver: order.distributor,
      )

      urls = FdcUrlBuilder.new(product_link)
      orderer = FdcBackorderer.new(user, urls)
      backorder = orderer.build_new_order(order)
      backorder.client = "https://openfoodnetwork.org.uk/api/dfc/enterprises/203468"

      expect(orderer).to receive(:send_order).and_return(backorder)
      expect {
        subject.place_order(user, order, orderer, backorder)
      }.to enqueue_job(CompleteBackorderJob).at(completion_time)
        .and change { exchange.semantic_links.count }.by(1)
    end
  end
end
