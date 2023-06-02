# frozen_string_literal: true

module CheckoutHelper
  def shipping_and_billing_match?(order)
    order.ship_address == order.bill_address
  end

  def guest_checkout_allowed?
    current_order.distributor.allow_guest_orders?
  end

  def checkout_adjustments_for(order, opts = {})
    exclude = opts[:exclude] || {}
    reject_zero_amount = opts.fetch(:reject_zero_amount, true)

    adjustments = order.all_adjustments.eligible.to_a

    # Remove tax adjustments and (optionally) shipping fees
    adjustments.reject! { |a| a.originator_type == 'Spree::TaxRate' }
    if exclude.include? :shipping
      adjustments.reject! { |a|
        a.originator_type == 'Spree::ShippingMethod'
      }
    end
    if exclude.include? :payment
      adjustments.reject! { |a|
        a.originator_type == 'Spree::PaymentMethod'
      }
    end
    if exclude.include? :line_item
      adjustments.reject! { |a|
        a.adjustable_type == 'Spree::LineItem'
      }
    end

    if reject_zero_amount
      adjustments.reject! { |a| a.amount == 0 }
    end

    adjustments
  end

  def checkout_line_item_fees(order)
    order.line_item_adjustments.enterprise_fee
  end

  def checkout_subtotal(order)
    order.item_total + checkout_line_item_fees(order).sum(:amount)
  end

  def display_checkout_subtotal(order)
    Spree::Money.new checkout_subtotal(order), currency: order.currency
  end

  def display_checkout_tax_total(order)
    Spree::Money.new order.total_tax, currency: order.currency
  end

  def display_checkout_taxes_hash(order)
    totals = OrderTaxAdjustmentsFetcher.new(order).totals

    totals.map do |tax_rate, tax_amount|
      {
        amount: Spree::Money.new(tax_amount, currency: order.currency),
        percentage: number_to_percentage(tax_rate.amount * 100, precision: 1),
        rate_amount: tax_rate.amount,
      }
    end.sort_by { |tax| tax[:rate_amount] }
  end

  def display_line_item_tax_rates(line_item)
    line_item.tax_rates.map { |tr| number_to_percentage(tr.amount * 100, precision: 1) }.join(", ")
  end

  def display_adjustment_tax_rates(adjustment)
    tax_rates = TaxRateFinder.tax_rates_of(adjustment)
    tax_rates.map { |tr| number_to_percentage(tr.amount * 100, precision: 1) }.join(", ")
  end

  def display_adjustment_amount(adjustment)
    Spree::Money.new(adjustment.amount, currency: adjustment.currency)
  end

  def display_checkout_total_less_tax(order)
    Spree::Money.new order.total - order.total_tax, currency: order.currency
  end

  def validated_input(name, path, args = {})
    attributes = {
      :required => true,
      :type => :text,
      :name => path,
      :id => path,
      "ng-model" => path,
      "ng-class" => "{error: !fieldValid('#{path}')}"
    }.merge args

    render "shared/validated_input", name: name, path: path, attributes: attributes
  end

  def validated_select(name, path, options, args = {})
    attributes = {
      :required => true,
      :id => path,
      "ng-model" => path,
      "ng-class" => "{error: !fieldValid('#{path}')}"
    }.merge args

    render "shared/validated_select", name: name, path: path, options: options,
                                      attributes: attributes
  end

  def payment_method_price(method, order)
    price = method.compute_amount(order)
    if price == 0
      t('checkout_method_free')
    else
      "{{ #{price} | localizeCurrency }}"
    end
  end

  def payment_or_shipping_price(method, order)
    return unless method

    price = method.compute_amount(order)
    if price.zero?
      t('checkout_method_free')
    else
      Spree::Money.new(price, currency: order.currency)
    end
  end

  def checkout_step
    params[:step]
  end

  def checkout_step?(step)
    checkout_step == step.to_s
  end

  def stripe_card_options(cards)
    cards.map do |cc|
      [
        "#{cc.brand} #{cc.last_digits} #{I18n.t(:card_expiry_abbreviation)}:" \
        "#{cc.month.to_s.rjust(2, '0')}/#{cc.year}", cc.id
      ]
    end
  end
end
