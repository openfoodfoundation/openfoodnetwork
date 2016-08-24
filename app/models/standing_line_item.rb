class StandingLineItem < ActiveRecord::Base
  belongs_to :standing_order
  belongs_to :variant, class_name: 'Spree::Variant'

  validates :standing_order, presence: true
  validates :variant, presence: true
  validates :quantity, { presence: true, numericality: { only_integer: true } }
end
