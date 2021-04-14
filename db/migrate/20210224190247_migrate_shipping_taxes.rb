class MigrateShippingTaxes < ActiveRecord::Migration[4.2]
  class Spree::Preference < ActiveRecord::Base; end
  class Spree::TaxCategory < ActiveRecord::Base
    has_many :tax_rates, class_name: "Spree::TaxRate", inverse_of: :tax_category
  end
  class Spree::Order < ActiveRecord::Base
    has_many :adjustments, as: :adjustable
    belongs_to :bill_address, foreign_key: :bill_address_id, class_name: 'Spree::Address'
    belongs_to :ship_address, foreign_key: :ship_address_id, class_name: 'Spree::Address'

    def tax_zone
      Spree::Zone.match(tax_address) || Spree::Zone.default_tax
    end

    def tax_address
      Spree::Config[:tax_using_ship_address] ? ship_address : bill_address
    end
  end
  class Spree::Address < ActiveRecord::Base; end
  class Spree::Shipment < ActiveRecord::Base
    has_many :adjustments, as: :adjustable
  end
  class Spree::ShippingMethod < ActiveRecord::Base; end
  class Spree::Zone < ActiveRecord::Base
    has_many :zone_members, dependent: :destroy, class_name: "Spree::ZoneMember", inverse_of: :zone
    has_many :tax_rates, class_name: "Spree::TaxRate", inverse_of: :zone

    def self.match(address)
      return unless (matches = includes(:zone_members).
        order('zone_members_count', 'created_at').
        select { |zone| zone.include? address })

      ['state', 'country'].each do |zone_kind|
        if (match = matches.detect { |zone| zone_kind == zone.kind })
          return match
        end
      end
      matches.first
    end

    def kind
      return unless zone_members.any? && zone_members.none? { |member| member.try(:zoneable_type).nil? }

      zone_members.last.zoneable_type.demodulize.underscore
    end

    def include?(address)
      return false unless address

      zone_members.any? do |zone_member|
        case zone_member.zoneable_type
        when 'Spree::Country'
          zone_member.zoneable_id == address.country_id
        when 'Spree::State'
          zone_member.zoneable_id == address.state_id
        else
          false
        end
      end
    end
  end
  class Spree::ZoneMember < ActiveRecord::Base
    belongs_to :zone, class_name: 'Spree::Zone', inverse_of: :zone_members
    belongs_to :zoneable, polymorphic: true
  end
  class Spree::TaxRate < ActiveRecord::Base
    belongs_to :zone, class_name: "Spree::Zone", inverse_of: :tax_rates
    belongs_to :tax_category, class_name: "Spree::TaxCategory", inverse_of: :tax_rates
    has_one :calculator, class_name: "Spree::Calculator", as: :calculable, dependent: :destroy
    accepts_nested_attributes_for :calculator
  end
  class Spree::Adjustment < ActiveRecord::Base
    belongs_to :adjustable, polymorphic: true
    belongs_to :originator, polymorphic: true
    belongs_to :source, polymorphic: true
    belongs_to :order, class_name: "Spree::Order"

    scope :shipping, -> { where(originator_type: 'Spree::ShippingMethod') }
  end

  def up
    return unless instance_uses_shipping_tax?

    create_shipping_tax_rates
    assign_to_shipping_methods
    migrate_tax_amounts_to_adjustments
  end

  def instance_uses_shipping_tax?
    Spree::Preference.find_by(key: '/spree/app_configuration/shipment_inc_vat')&.value || false
  end

  def instance_shipping_tax_rate
    Spree::Preference.find_by(key: '/spree/app_configuration/shipping_tax_rate')&.value || 0.0
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
    shipping_tax_rates = Spree::TaxRate.where(tax_category: shipping_tax_category).to_a

    # Migrate all shipping tax amounts from shipment field to tax adjustments
    Spree::Adjustment.shipping.where("included_tax <> 0").includes(:source, :order).find_each do |shipping_fee|
      shipment = shipping_fee.source
      order = shipping_fee.order
      next if order.nil?

      tax_rate = shipping_tax_rates.detect{ |rate| rate.zone == order.tax_zone }

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
