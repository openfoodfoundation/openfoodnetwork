# frozen_string_literal: true

class CacheService
  HOME_STATS_EXPIRY = 1.day.freeze
  FILTERS_EXPIRY = 30.seconds.freeze
  SHOPS_EXPIRY = 15.seconds.freeze

  def self.cache(cache_key, options = {})
    Rails.cache.fetch cache_key.to_s, options do
      yield
    end
  end

  # Yields a cached query, expired by the most recently updated record for a given class.
  # E.g: if *any* Spree::Taxon record is updated, all keys based on Spree::Taxon will auto-expire.
  def self.cached_data_by_class(cache_key, cached_class)
    Rails.cache.fetch "#{cache_key}-#{cached_class}-#{latest_timestamp_by_class(cached_class)}" do
      yield
    end
  end

  # Gets the :updated_at value of the most recently updated record for a given class, and returns
  # it as a timestamp, eg: `1583836069`.
  def self.latest_timestamp_by_class(cached_class)
    cached_class.maximum(:updated_at).to_i
  end
end
