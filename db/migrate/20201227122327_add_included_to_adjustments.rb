class AddIncludedToAdjustments < ActiveRecord::Migration[4.2]
  class Spree::TaxRate < ActiveRecord::Base; end

  class Spree::Adjustment < ActiveRecord::Base
    belongs_to :originator, polymorphic: true
  end

  def up
    add_column :spree_adjustments, :included, :boolean, default: false
    Spree::Adjustment.reset_column_information

    inclusive_tax_rates = Spree::TaxRate.where(included_in_price: true)

    # Set included boolean to true on all adjustments based on price-inclusive tax rates
    Spree::Adjustment.where(originator_type: 'Spree::TaxRate', originator_id: inclusive_tax_rates).
      update_all(included: true)
  end

  def down
    remove_column :spree_adjustments, :included
  end
end
