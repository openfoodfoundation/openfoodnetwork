# frozen_string_literal: true

require 'spec_helper'

describe CacheService do
  let(:rails_cache) { Rails.cache }

  describe "#cache" do
    before do
      allow(rails_cache).to receive(:fetch)
    end

    it "provides a wrapper for basic #fetch calls to Rails.cache" do
      CacheService.cache("test-cache-key", expires_in: 10.seconds) do
        "TEST"
      end

      expect(rails_cache).to have_received(:fetch).with("test-cache-key", expires_in: 10.seconds)
    end
  end

  describe "#cached_data_by_class" do
    let(:timestamp) { Time.now.to_f }

    before do
      allow(rails_cache).to receive(:fetch)
      allow(Enterprise).to receive(:maximum).with(:updated_at).and_return(timestamp)
    end

    it "caches data by timestamp for last record of that class" do
      CacheService.cached_data_by_class("test-cache-key", Enterprise) do
        "TEST"
      end

      expect(rails_cache).to have_received(:fetch).with("test-cache-key-Enterprise-#{timestamp}")
    end
  end

  describe "#latest_timestamp_by_class" do
    let!(:taxon1) { create(:taxon) }
    let!(:taxon2) { create(:taxon) }

    it "gets the :updated_at value of the last record for a given class and returns a timestamp" do
      taxon1.touch
      expect(CacheService.latest_timestamp_by_class(Spree::Taxon)).
        to eq taxon1.reload.updated_at.to_f

      taxon2.touch
      expect(CacheService.latest_timestamp_by_class(Spree::Taxon)).
        to eq taxon2.reload.updated_at.to_f
    end
  end
end
