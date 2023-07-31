# frozen_string_literal: true

class CacheService
  HOME_STATS_EXPIRY = 1.day.freeze
  FILTERS_EXPIRY = 30.seconds.freeze
  SHOPS_EXPIRY = 15.seconds.freeze

  def self.cache(cache_key, options = {}, &)
    Rails.cache.fetch(cache_key.to_s, options, &)
  end

  # Yields a cached query, expired by the most recently updated record for a given class.
  # E.g: if *any* Spree::Taxon record is updated, all keys based on Spree::Taxon will auto-expire.
  def self.cached_data_by_class(cache_key, cached_class, &)
    Rails.cache.fetch("#{cache_key}-#{cached_class}-#{latest_timestamp_by_class(cached_class)}",
                      &)
  end

  # Gets the :updated_at value of the most recently updated record for a given class, and returns
  # it as a timestamp, eg: `1583836069`.
  def self.latest_timestamp_by_class(cached_class)
    cached_class.maximum(:updated_at).to_f
  end

  def self.home_stats(statistic, &)
    Rails.cache.fetch("home_stats_count_#{statistic}",
                      expires_in: HOME_STATS_EXPIRY,
                      race_condition_ttl: 10, &)
  end

  module FragmentCaching
    # Rails' caching in views is called "Fragment Caching" and uses some slightly different logic.
    # Note: keys supplied here are actually prepended with "views/" under the hood.

    def self.ams_all_taxons
      [
        "inject-all-taxons-#{CacheService.latest_timestamp_by_class(Spree::Taxon)}",
        { skip_digest: true }
      ]
    end

    def self.ams_all_properties
      [
        "inject-all-properties-#{CacheService.latest_timestamp_by_class(Spree::Property)}",
        { skip_digest: true }
      ]
    end

    def self.ams_shops
      [
        "shops/index/inject_enterprises",
        { expires_in: SHOPS_EXPIRY, skip_digest: true }
      ]
    end

    def self.ams_shop(enterprise)
      [
        "enterprises/shop/inject_enterprise_shopfront-#{enterprise.id}",
        { expires_in: SHOPS_EXPIRY, skip_digest: true }
      ]
    end
  end
end
