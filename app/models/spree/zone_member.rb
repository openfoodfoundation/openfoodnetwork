# frozen_string_literal: true

module Spree
  class ZoneMember < ApplicationRecord
    self.belongs_to_required_by_default = false

    belongs_to :zone, class_name: 'Spree::Zone', counter_cache: true, inverse_of: :zone_members
    belongs_to :zoneable, polymorphic: true

    def name
      return nil if zoneable.nil?

      zoneable.name
    end
  end
end
