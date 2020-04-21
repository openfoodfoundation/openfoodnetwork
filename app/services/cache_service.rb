# frozen_string_literal: true

class CacheService
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
  # it as a timestamp, eg: `1583836069`. The timestamp for the class is stored in a memoized hash,
  # so the same value isn't fetched from the database more than once per request cycle.
  def self.latest_timestamp_by_class(cached_class)
    @memoized_timestamps ||= Hash.new do |hash, key|
      hash[key] = key.maximum(:updated_at).to_i
    end
    @memoized_timestamps[cached_class]
  end
end
