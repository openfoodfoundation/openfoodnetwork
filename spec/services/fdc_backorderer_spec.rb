# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FdcBackorderer do
  let(:order) { create(:completed_order_with_totals) }
  let(:account) {
    OidcAccount.new(
      uid: "testdfc@protonmail.com",
      refresh_token: ENV.fetch("OPENID_REFRESH_TOKEN"),
      updated_at: 1.day.ago,
    )
  }

  before do
    order.distributor.owner.oidc_account = account
  end

  describe "#find_or_build_order" do
    it "builds an order object" do
      account.updated_at = Time.zone.now
      stub_request(:get, FdcBackorderer::FDC_ORDERS_URL)
        .to_return(status: 200, body: "{}")

      backorder = subject.find_or_build_order(order)

      expect(backorder.semanticId).to match %r{^https.*/\#$}
      expect(backorder.lines).to eq []
    end

    it "finds an order object", vcr: true do
      backorder = subject.find_or_build_order(order)

      expect(backorder.semanticId).to match %r{^https.*/[0-9]+$}
      expect(backorder.lines.count).to eq 1
    end
  end
end
