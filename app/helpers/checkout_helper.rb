# frozen_string_literal: true

module CheckoutHelper
  def guest_checkout_allowed?
    current_order.distributor.allow_guest_orders?
  end

  def checkout_adjustments_for(order, opts = {})
    exclude = opts[:exclude] || {}

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

    enterprise_fee_adjustments = adjustments.select { |a|
      a.originator_type == 'EnterpriseFee' && a.adjustable_type != 'Spree::LineItem'
    }
    adjustments.reject! { |a|
      a.originator_type == 'EnterpriseFee' && a.adjustable_type != 'Spree::LineItem'
    }
    unless exclude.include? :admin_and_handling
      adjustments << Spree::Adjustment.new(
        label: I18n.t(:orders_form_admin), amount: enterprise_fee_adjustments.sum(&:amount)
      )
    end

    adjustments
  end

  def display_line_item_fees_total_for(order)
    Spree::Money.new order.adjustments.enterprise_fee.sum(:amount), currency: order.currency
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

    totals.each_with_object({}) do |(tax_rate, tax_amount), hash|
      hash[number_to_percentage(tax_rate.amount * 100, precision: 1)] =
        Spree::Money.new tax_amount, currency: order.currency
    end
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
end
