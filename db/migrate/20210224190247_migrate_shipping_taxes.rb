class MigrateShippingTaxes < ActiveRecord::Migration
  def up
    return unless instance_uses_shipping_tax?

    create_shipping_tax_rates
    assign_to_shipping_methods
    migrate_tax_amounts_to_adjustments
  end

  def instance_uses_shipping_tax?
    Spree::Preference.find_by(key: '/spree/app_configuration/shipment_inc_vat').value
  end

  def instance_shipping_tax_rate
    Spree::Preference.find_by(key: '/spree/app_configuration/shipping_tax_rate').value
  end
  
  def shipping_tax_category
    @shipping_tax_category ||= Spree::TaxCategory.create(name: I18n.t(:shipping))
  end
  
  def create_shipping_tax_rates
    # Create a shipping tax rate for each zone, set to current default rate
    Spree::Zone.all.each do |tax_zone|
      Spree::TaxRate.create!(
        name: shipping_rate_label(tax_zone),
        zone: tax_zone,
        tax_category: shipping_tax_category,
        amount: instance_shipping_tax_rate,
        included_in_price: true,
        calculator: Calculator::DefaultTax.new
      )
    end
  end

  def assign_to_shipping_methods
    # Assign the new default shipping tax category to all existing shipping methods
    Spree::ShippingMethod.update_all(tax_category_id: shipping_tax_category.id)
  end
  
  def migrate_tax_amounts_to_adjustments
    # Migrate all shipping tax amounts from shipment field to tax adjustments
    Spree::Adjustment.shipping.where("included_tax <> 0").includes(:source, :order).find_each do |shipping_fee|
      shipment = shipping_fee.source
      order = shipping_fee.order
      next if order.nil?

      tax_rate = Spree::TaxRate.find_by(tax_category: shipping_tax_category, zone: order.tax_zone)

      # Move all tax totals to adjustments
      Spree::Adjustment.create!(
        label: tax_adjustment_label(tax_rate),
        amount: shipping_fee.included_tax,
        included: true,
        order_id: order.id,
        state: "closed",
        adjustable_type: "Spree::Shipment",
        adjustable_id: shipment.id,
        source_type: "Spree::Shipment",
        source_id: shipment.id,
        originator_type: "Spree::TaxRate",
        originator_id: tax_rate.id
      )

      # Update shipment included tax total
      shipment.update_columns(
        included_tax_total: shipping_fee.included_tax
      )
    end
  end

  def shipping_rate_label(zone)
    I18n.t(:shipping) + " - #{zone.name.chomp('_VAT')}"
  end

  def tax_adjustment_label(tax_rate)
    label = ""
    label << tax_rate.name
    label << " #{tax_rate.amount * 100}%"
    label << " (#{I18n.t('models.tax_rate.included_in_price')})"
    label
  end
end
