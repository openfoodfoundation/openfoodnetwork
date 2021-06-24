# It turns out the good_migrations gem doesn't play nicely with loading classes on polymorphic
# associations. The only workaround seems to be to load the class explicitly, which essentially
# skips the whole point of good_migrations... :/
require 'enterprise_fee'
require 'concerns/balance'
require 'spree/order'

class MigrateEnterpriseFeeTaxAmounts < ActiveRecord::Migration[5.0]
  class Spree::Adjustment < ApplicationRecord
    belongs_to :originator, -> { with_deleted }, polymorphic: true
    belongs_to :adjustable, polymorphic: true
    belongs_to :order, class_name: "Spree::Order"
    belongs_to :tax_category, class_name: 'Spree::TaxCategory'
    has_many :adjustments, as: :adjustable, dependent: :destroy

    scope :enterprise_fee, -> { where(originator_type: 'EnterpriseFee') }
  end
  class Spree::LineItem < ApplicationRecord
    belongs_to :variant, class_name: "Spree::Variant"
    has_one :product, through: :variant
  end
  class Spree::Variant < ApplicationRecord
    belongs_to :product, class_name: 'Spree::Product'
    has_many :line_items, inverse_of: :variant
  end
  class Spree::Product < ApplicationRecord
    belongs_to :tax_category, class_name: 'Spree::TaxCategory'
    has_many :variants, class_name: 'Spree::Variant'
  end
  class Spree::TaxCategory < ApplicationRecord
    has_many :tax_rates, dependent: :destroy, inverse_of: :tax_category
  end
  class Spree::TaxRate < ApplicationRecord
    belongs_to :zone, class_name: "Spree::Zone", inverse_of: :tax_rates
    belongs_to :tax_category, class_name: "Spree::TaxCategory", inverse_of: :tax_rates
    has_many :adjustments, as: :originator
  end

  def up
    migrate_enterprise_fee_taxes!
  end

  def migrate_enterprise_fee_taxes!
    Spree::Adjustment.enterprise_fee.where('included_tax <> 0').
      includes(:originator, :adjustable).find_each do |fee|

      tax_category = tax_category_for(fee)
      tax_rate = tax_rate_for(tax_category)

      fee.update_columns(tax_category_id: tax_category.id) if tax_category.present?

      Spree::Adjustment.create!(
        label: tax_adjustment_label(tax_rate),
        amount: fee.included_tax,
        order_id: fee.order_id,
        adjustable: fee,
        originator_type: "Spree::TaxRate",
        originator_id: tax_rate&.id,
        state: "closed",
        included: true
      )
    end
  end

  def tax_adjustment_label(tax_rate)
    if tax_rate.nil?
      I18n.t('included_tax')
    else
      "#{tax_rate.name} #{tax_rate.amount * 100}% (#{I18n.t('models.tax_rate.included_in_price')})"
    end
  end

  def tax_category_for(fee)
    enterprise_fee = fee.originator

    return if enterprise_fee.nil?

    if line_item_fee?(fee) && enterprise_fee.inherits_tax_category?
      fee.adjustable&.product&.tax_category
    else
      enterprise_fee.tax_category
    end
  end

  def line_item_fee?(fee)
    fee.adjustable_type == "Spree::LineItem"
  end

  def tax_rate_for(tax_category)
    tax_category&.tax_rates&.first
  end
end
