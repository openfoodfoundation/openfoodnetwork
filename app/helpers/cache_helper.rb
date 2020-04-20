# frozen_string_literal: true

module CacheHelper
  # Yields a cached query, expired by the most recently updated record of a given class
  def cached_data_by_class(cache_key, cached_class)
    Rails.cache.fetch "#{cached_class}-#{cache_key}-#{latest_timestamp_by_class(cached_class)}" do
      yield
    end
  end

  # Gets the updated_at timestamp of the most recently updated record of a given class
  def latest_timestamp_by_class(cached_class)
    @_memoized_timestamps ||= Hash.new do |hash, key|
      hash[key] = key.maximum(:updated_at).to_i
    end
    @_memoized_timestamps[cached_class]
  end
end
