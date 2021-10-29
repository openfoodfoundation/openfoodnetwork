# frozen_string_literal: true

# Whitelists model attributes, scopes, and associations that can be searched on with Ransack.
# Exposes methods for defining the whitelists, eg:
#
# class Widget < ApplicationRecord
#   searchable_attributes :number, :state
#   searchable_scopes :activated, :disabled
#
#   ...
# end

module Searchable
  extend ActiveSupport::Concern

  DEFAULT_SEARCHABLE_ATTRIBUTES = [
    :id, :name, :description, :created_at, :updated_at, :completed_at, :deleted_at
  ].freeze

  included do
    class_attribute :whitelisted_search_attributes, instance_accessor: false, default: []
    class_attribute :whitelisted_search_associations, instance_accessor: false, default: []
    class_attribute :whitelisted_search_scopes, instance_accessor: false, default: []
  end

  class_methods do
    def ransackable_associations(*_args)
      whitelisted_search_associations.map(&:to_s)
    end

    def ransackable_attributes(*_args)
      (DEFAULT_SEARCHABLE_ATTRIBUTES | whitelisted_search_attributes).map(&:to_s)
    end

    def ransackable_scopes(*_args)
      whitelisted_search_scopes.map(&:to_s)
    end

    private

    def searchable_attributes(*attrs)
      self.whitelisted_search_attributes = attrs
    end

    def searchable_associations(*attrs)
      self.whitelisted_search_associations = attrs
    end

    def searchable_scopes(*attrs)
      self.whitelisted_search_scopes = attrs
    end
  end
end
