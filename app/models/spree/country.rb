# frozen_string_literal: true

module Spree
  class Country < ApplicationRecord
    has_many :states, -> { order('name ASC') }, dependent: :destroy

    validates :name, :iso_name, presence: true

    def <=>(other)
      name <=> other.name
    end

    def to_s
      name
    end
  end
end
