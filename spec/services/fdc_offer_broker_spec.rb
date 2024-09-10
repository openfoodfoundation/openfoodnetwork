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
    it "finds a linked wholesale offer", vcr: true do
      solution = subject.best_offer(product.semanticId)

      # These values depend on the test data but are a good sanity check:
      expect(product.name).to eq "Baked British Beans - Retail can, 400g (can)"
      expect(solution.product.name).to eq "Baked British Beans - Case, 12 x 400g (can)"
      expect(solution.factor).to eq 12
      expect(solution.offer.offeredItem).to eq solution.product
    end
  end
end
