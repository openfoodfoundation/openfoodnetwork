# frozen_string_literal: true

class ExchangeVariant < ApplicationRecord
  belongs_to :exchange
  belongs_to :variant, class_name: 'Spree::Variant'
end
