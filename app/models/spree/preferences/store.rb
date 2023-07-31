# frozen_string_literal: true

# Use singleton class Spree::Preferences::Store.instance to access
#
# StoreInstance has a persistence flag that is on by default,
# but we disable database persistence in testing to speed up tests
#

require 'singleton'

module Spree
  module Preferences
    class StoreInstance
      attr_accessor :persistence

      def initialize
        @cache = Rails.cache
        @persistence = true
      end

      def set(key, value, type)
        @cache.write(key, value)
        persist(key, value, type)
      end

      def exist?(key)
        @cache.exist?(key) ||
          (should_persist? && Spree::Preference.where(key: key).exists?)
      end

      def get(key, fallback = nil)
        # return the retrieved value, if it's in the cache
        # use unless nil? incase the value is actually boolean false
        #
        unless (val = @cache.read(key)).nil?
          return val
        end

        # If it's not in the cache, maybe it's in the database, but has been cleared from the cache
        # does it exist in the database?
        if should_persist? && Spree::Preference.table_exists?
          preference = Spree::Preference.find_by(key: key)
          if preference
            # it does exist, so let's put it back into the cache
            @cache.write(preference.key, preference.value)

            # and return the value
            return preference.value
          end
        end

        unless fallback.nil?
          # cache fallback so we won't hit the db above on
          # subsequent queries for the same key
          #
          @cache.write(key, fallback)
        end

        fallback
      end

      def delete(key)
        return if key.nil?

        @cache.delete(key)
        destroy(key)
      end

      def clear_cache
        @cache.clear
      end

      private

      def persist(cache_key, value, type)
        return unless should_persist?

        preference = Spree::Preference.where(key: cache_key).first_or_initialize
        preference.value = value
        preference.value_type = type
        preference.save
      end

      def destroy(cache_key)
        return unless should_persist?

        preference = Spree::Preference.find_by(key: cache_key)
        preference&.destroy
      end

      def should_persist?
        @persistence && Spree::Preference.connected? && Spree::Preference.table_exists?
      end
    end

    class Store < StoreInstance
      include Singleton
    end
  end
end
