class StandingLineItem < ActiveRecord::Base
  belongs_to :standing_order, inverse_of: :standing_line_items
  belongs_to :variant, class_name: 'Spree::Variant'

  validates :standing_order, presence: true
  validates :variant, presence: true
  validates :quantity, { presence: true, numericality: { only_integer: true } }

  def total_estimate
    (price_estimate || 0) * (quantity || 0)
  end

  default_scope order('id ASC')
end
