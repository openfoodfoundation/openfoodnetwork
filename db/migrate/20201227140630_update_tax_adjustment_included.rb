class UpdateTaxAdjustmentIncluded < ActiveRecord::Migration
  def up
    inclusive_tax_rates = Spree::TaxRate.where(included_in_price: true).pluck(:id)

    return if inclusive_tax_rates.empty?

    # Set the #included flag on all tax adjustments with inclusive rates
    Spree::Adjustment.
      where(originator_type: 'Spree::TaxRate', originator_id: inclusive_tax_rates).
      find_each do |adjustment|

      adjustment.update_column(:included, true)
    end
  end
end
