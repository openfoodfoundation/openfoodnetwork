class Invoice::DataPresenter::LineItem  < Invoice::DataPresenter::Base
  attributes :quantity, :price_with_adjustments, :added_tax, :included_tax, :currency
  attributes_with_presenter :variant
  relevant_attributes :quantity
  delegate :name_to_display, :options_text, to: :variant

  def display_amount_with_adjustments
    Spree::Money.new(price_with_adjustments, currency: currency)
  end

  def display_line_items_taxes(display_zero = true)
    if included_tax.positive?
      Spree::Money.new( included_tax, currency: currency)
    elsif added_tax.positive?
      Spree::Money.new( added_tax, currency: currency)
    elsif display_zero
      Spree::Money.new(0.00, currency: currency)
    end
  end
end
