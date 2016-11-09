class StandingLineItem < ActiveRecord::Base
  belongs_to :standing_order, inverse_of: :standing_line_items
  belongs_to :variant, class_name: 'Spree::Variant'

  validates :standing_order, presence: true
  validates :variant, presence: true
  validates :quantity, { presence: true, numericality: { only_integer: true } }

  def available_from?(shop, schedule)
    Spree::Variant.joins(exchanges: { order_cycle: :schedules})
    .where(id: variant_id, schedules: { id: schedule}, exchanges: { incoming: false, receiver_id: shop })
    .any?
  end
end
