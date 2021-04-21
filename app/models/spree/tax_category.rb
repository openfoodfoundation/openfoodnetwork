# frozen_string_literal: true

module Spree
  class TaxCategory < ApplicationRecord
    acts_as_paranoid
    validates :name, presence: true, uniqueness: { scope: :deleted_at }

    has_many :tax_rates, dependent: :destroy, inverse_of: :tax_category

    before_save :set_default_category

    def set_default_category
      # set existing default tax category to false if this one has been marked as default

      return unless is_default && tax_category = self.class.find_by(is_default: true)
      return if tax_category == self

      tax_category.update_columns(
        is_default: false,
        updated_at: Time.zone.now
      )
    end
  end
end
