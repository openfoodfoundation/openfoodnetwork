# It turns out the good_migrations gem doesn't play nicely with loading classes on polymorphic
# associations. The only workaround seems to be to load the class explicitly, which essentially
# skips the whole point of good_migrations... :/

class MigrateEnterpriseFeeTaxAmounts < ActiveRecord::Migration[5.0]
  module Spree
    class Adjustment < ApplicationRecord
      self.table_name =  "spree_adjustments"

      belongs_to :originator, -> { with_deleted }, polymorphic: true
      belongs_to :adjustable, polymorphic: true
      belongs_to :order
      belongs_to :tax_category
      has_many :adjustments, as: :adjustable, dependent: :destroy

      scope :enterprise_fee, -> { where(originator_type: 'EnterpriseFee') }
    end
    class LineItem < ApplicationRecord
      self.table_name =  "spree_line_items"

      belongs_to :variant
      has_one :product, through: :variant
    end
    class Variant < ApplicationRecord
      self.table_name =  "spree_variants"

      belongs_to :product
      has_many :line_items, inverse_of: :variant
    end
    class Product < ApplicationRecord
      self.table_name =  "spree_products"

      belongs_to :tax_category
      has_many :variants
    end
    class TaxCategory < ApplicationRecord
      self.table_name =  "spree_tax_categories"

      has_many :tax_rates, dependent: :destroy, inverse_of: :tax_category
    end
    class TaxRate < ApplicationRecord
      self.table_name =  "spree_tax_rates"

      belongs_to :zone, inverse_of: :tax_rates
      belongs_to :tax_category, inverse_of: :tax_rates
      has_many :adjustments, as: :originator
    end
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
