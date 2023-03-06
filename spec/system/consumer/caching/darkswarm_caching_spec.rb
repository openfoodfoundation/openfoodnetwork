# frozen_string_literal: true

require "system_helper"

describe "Darkswarm data caching", caching: true do
  let!(:taxon) { create(:taxon, name: "Cached Taxon") }
  let!(:property) { create(:property, presentation: "Cached Property") }

  let!(:producer) { create(:supplier_enterprise) }
  let!(:distributor) {
    create(:distributor_enterprise, with_payment_and_shipping: true, is_primary_producer: true)
  }
  let!(:product) {
    create(:simple_product, supplier: producer, primary_taxon: taxon, taxons: [taxon],
                            properties: [property])
  }
  let!(:order_cycle) {
    create(:simple_order_cycle, distributors: [distributor], coordinator: distributor)
  }
  let(:exchange) { order_cycle.exchanges.outgoing.where(receiver_id: distributor.id).first }

  before do
    exchange.variants << product.variants.first
  end

  describe "caching injected taxons and properties" do
    it "caches taxons and properties" do
      expect(Spree::Taxon).to receive(:all).at_least(:once).and_call_original
      expect(Spree::Property).to receive(:all).at_least(:once).and_call_original

      visit shops_path

      expect(Spree::Taxon).to_not receive(:all)
      expect(Spree::Property).to_not receive(:all)

      visit shops_path
    end

    it "invalidates caches for taxons and properties" do
      visit shops_path

      taxon_timestamp1 = CacheService.latest_timestamp_by_class(Spree::Taxon)
      expect_cached "views/#{CacheService::FragmentCaching.ams_all_taxons[0]}"

      property_timestamp1 = CacheService.latest_timestamp_by_class(Spree::Property)
      expect_cached "views/#{CacheService::FragmentCaching.ams_all_properties[0]}"

      toggle_filters

      within "#hubs .filter-box" do
        expect(page).to have_content taxon.name
        expect(page).to have_content property.presentation
      end

      # Update rows which should also update the timestamp.
      # The timestamp represents seconds, so waiting one second is enough.
      sleep 1
      taxon.update!(name: "Changed Taxon")
      property.update!(presentation: "Changed Property")

      # Clear timed shops cache so we can test uncached supplied properties
      clear_shops_cache

      visit shops_path

      # Wait for /shops page to load properly before checking for new timestamps
      expect(page).to_not have_selector ".row.filter-box"

      taxon_timestamp2 = CacheService.latest_timestamp_by_class(Spree::Taxon)
      expect_cached "views/#{CacheService::FragmentCaching.ams_all_taxons[0]}"

      property_timestamp2 = CacheService.latest_timestamp_by_class(Spree::Property)
      expect_cached "views/#{CacheService::FragmentCaching.ams_all_properties[0]}"

      expect(taxon_timestamp1).to_not eq taxon_timestamp2
      expect(property_timestamp1).to_not eq property_timestamp2

      toggle_filters

      within "#hubs .filter-box" do
        expect(page).to have_content "Changed Taxon"
        expect(page).to have_content "Changed Property"
      end
    end
  end

  def expect_cached(key)
    expect(Rails.cache.exist?(key)).to be true
  end

  def clear_shops_cache
    cache_key = "views/#{CacheService::FragmentCaching.ams_shops[0]}"
    Rails.cache.delete cache_key
  end
end
