# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FdcOfferBroker do
  subject { FdcOfferBroker.new(catalog) }
  let(:catalog) { BackorderJob.load_catalog(user) }
  let(:user) { build(:testdfc_user) }
  let(:product) {
    catalog.find { |item| item.semanticType == "dfc-b:SuppliedProduct" }
  }

  describe ".best_offer" do
    it "finds a linked offer", vcr: true do
      offer = subject.best_offer(product.semanticId)

      # This is the URL structure on the FDC API:
      expect(offer.semanticId).to eq "#{product.semanticId}/Offer"

      # Well, if you ask the orders endpoint, you actually get different ids
      # for the same offers...
    end
  end
end
