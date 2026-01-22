# frozen_string_literal: true

RSpec.describe FdcOfferBroker do
  subject { FdcOfferBroker.new(catalog) }
  let(:catalog) {
    VCR.use_cassette(:fdc_catalog) {
      DfcCatalog.load(user, catalog_url)
    }
  }
  let(:catalog_url) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts"
  }
  let(:product_link) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635"
  }
  let(:user) { build(:testdfc_user) }
  let(:product) {
    catalog.products.first
  }

  describe ".best_offer" do
    it "finds a linked wholesale offer" do
      solution = subject.best_offer(product.semanticId)

      # These values depend on the test data but are a good sanity check:
      expect(product.name).to eq "Baked British Beans - Retail can, 400g (can)"
      expect(solution.product.name).to eq "Baked British Beans - Case, 12 x 400g (can)"
      expect(solution.factor).to eq 12
      expect(solution.offer.offeredItem).to eq solution.product
    end

    it "falls back to the original product offer" do
      solution = subject.best_offer(product.semanticId)
      fallback_solution = subject.best_offer(solution.product.semanticId)

      # These values depend on the test data but are a good sanity check:
      expect(fallback_solution.product.name).to eq "Baked British Beans - Case, 12 x 400g (can)"
      expect(fallback_solution.factor).to eq 1
      expect(fallback_solution.offer.offeredItem).to eq fallback_solution.product
    end
  end

  describe ".wholesale_to_retail" do
    it "finds a linked retail offer" do
      offer_solution = subject.best_offer(product.semanticId)
      retail_solution = subject.wholesale_to_retail(offer_solution.product.semanticId)

      expect(retail_solution.retail_product_id).to eq product.semanticId
      expect(retail_solution.factor).to eq 12
    end

    it "falls back to the wholesale product id" do
      retail_solution = subject.wholesale_to_retail(product.semanticId)

      expect(retail_solution.retail_product_id).to eq product.semanticId
      expect(retail_solution.factor).to eq 1
    end
  end
end
