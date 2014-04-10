module CheckoutHelper
  def checkout_adjustments_for_summary(order)
    adjustments = order.adjustments.eligible

    adjustments.reject! { |a| a.originator_type == 'Spree::TaxRate' && a.amount == 0 }

    enterprise_fee_adjustments = adjustments.select { |a| a.originator_type == 'EnterpriseFee' }
    adjustments.reject! { |a| a.originator_type == 'EnterpriseFee' }
    adjustments << Spree::Adjustment.new(label: 'Distribution', amount: enterprise_fee_adjustments.sum(&:amount))

    adjustments
  end

  def validated_input(name, path, args = {})
    defaults = {
      required: true,
      type: :text
    }.merge args
    render partial: "shared/validated_input", locals: {name: name, path: path}.merge(defaults)
  end
end
