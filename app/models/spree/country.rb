# frozen_string_literal: true

module Spree
  class Country < ApplicationRecord
    has_many :states, -> { order('name ASC') }

    validates :name, :iso_name, presence: true

    def self.cached_find_by(attrs)
      Rails.cache.fetch("countries/#{attrs.hash}", expires_in: 1.hour) do
        find_by(attrs)
      end
    end

    def <=>(other)
      name <=> other.name
    end

    def to_s
      name
    end
  end
end
