# frozen_string_literal: true

require 'open_food_network/property_merge'

class Api::EnterpriseSerializer < ActiveModel::Serializer
  # We reference this here because otherwise the serializer complains about its absence
  # rubocop:disable Lint/Void
  Api::IdSerializer
  # rubocop:enable Lint/Void

  def serializable_hash
    cached_serializer_hash.merge uncached_serializer_hash
  end

  private

  def cached_serializer_hash
    Api::CachedEnterpriseSerializer.new(object, @options).serializable_hash || {}
  end

  def uncached_serializer_hash
    Api::UncachedEnterpriseSerializer.new(object, @options).serializable_hash || {}
  end
end
