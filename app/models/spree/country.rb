# frozen_string_literal: true

module Spree
  class Country < ApplicationRecord
    has_many :states, -> { order('name ASC') }, dependent: :destroy

    validates :name, :iso_name, presence: true

    def self.find_by_cached(attrs)
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
