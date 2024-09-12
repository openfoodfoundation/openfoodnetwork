# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BackorderJob do
  let(:order) { create(:completed_order_with_totals) }
  let(:variant) { order.variants.first }
  let(:user) { order.distributor.owner }
  let(:product_link) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635"
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
      BackorderJob.check_stock(order) # and not web requests were made
    end

    it "places an order", vcr: true do
      order.order_cycle = create(
        :simple_order_cycle,
        distributors: [order.distributor],
        variants: [variant],
      )
      variant.on_demand = true
      variant.on_hand = -3
      variant.semantic_links << SemanticLink.new(
        semantic_id: product_link
      )

      expect {
        BackorderJob.check_stock(order)
      }.to enqueue_job CompleteBackorderJob

      # We ordered a case of 12 cans: -3 + 12 = 9
      expect(variant.on_hand).to eq 9

      # Clean up after ourselves:
      perform_enqueued_jobs(only: CompleteBackorderJob)
    end
  end
end
