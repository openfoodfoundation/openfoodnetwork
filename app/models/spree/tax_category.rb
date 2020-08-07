# frozen_string_literal: true

module Spree
  class TaxCategory < ActiveRecord::Base
    acts_as_paranoid
    validates :name, presence: true, uniqueness: { scope: :deleted_at }

    has_many :tax_rates, dependent: :destroy

    before_save :set_default_category

    def set_default_category
      # set existing default tax category to false if this one has been marked as default

      return unless is_default && tax_category = self.class.find_by(is_default: true)

      tax_category.update_column(:is_default, false) unless tax_category == self
    end
  end
end
