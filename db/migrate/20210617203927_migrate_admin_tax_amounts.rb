class MigrateAdminTaxAmounts < ActiveRecord::Migration[6.0]
  class Spree::Adjustment < ApplicationRecord
    belongs_to :originator, polymorphic: true
    belongs_to :adjustable, polymorphic: true
    belongs_to :order, class_name: "Spree::Order"
    belongs_to :tax_category, class_name: 'Spree::TaxCategory'
    has_many :adjustments, as: :adjustable, dependent: :destroy

    scope :admin, -> { where(originator_type: nil) }
  end

  def up
    migrate_admin_taxes!
  end

  def migrate_admin_taxes!
    Spree::Adjustment.admin.where('included_tax <> 0').includes(:order).find_each do |adjustment|

      tax_rate = find_tax_rate(adjustment)
      tax_category = tax_rate&.tax_category
      label = tax_adjustment_label(tax_rate)

      adjustment.update_columns(tax_category_id: tax_category.id) if tax_category.present?

      Spree::Adjustment.create!(
        label: label,
        amount: adjustment.included_tax,
        order_id: adjustment.order_id,
        adjustable: adjustment,
        originator_type: "Spree::TaxRate",
        originator_id: tax_rate&.id,
        state: "closed",
        included: true
      )
    end
  end

  def find_tax_rate(adjustment)
    amount = adjustment.amount
    included_tax = adjustment.included_tax
    approximation = (included_tax / (amount - included_tax))

    return if approximation.infinite? || approximation.zero? || approximation.nan?

    applicable_rates(adjustment).min_by{ |rate| (rate.amount - approximation).abs  }
  end

  def applicable_rates(adjustment)
    return [] unless adjustment.order&.distributor_id.present?

    Spree::TaxRate.match(adjustment.order)
  end

  def tax_adjustment_label(tax_rate)
    if tax_rate.nil?
      I18n.t('included_tax')
    else
      "#{tax_rate.name} #{tax_rate.amount * 100}% (#{I18n.t('models.tax_rate.included_in_price')})"
    end
  end
end
