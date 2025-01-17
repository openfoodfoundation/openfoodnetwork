# frozen_string_literal: true

module Spree
  class StockLocation < ApplicationRecord
    self.belongs_to_required_by_default = false
    self.ignored_columns += [:backorderable_default, :active]

    belongs_to :state, class_name: 'Spree::State'
    belongs_to :country, class_name: 'Spree::Country'

    validates :name, presence: true
  end
end
