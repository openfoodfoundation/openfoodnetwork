class UpgradeAdjustments < ActiveRecord::Migration
  def up
    # Temporarily make originator association available
    Spree::Adjustment.class_eval do
      belongs_to :originator, polymorphic: true
    end
    # Shipping adjustments are now tracked as fields on the object
    Spree::Adjustment.where(:source_type => "Spree::Shipment").find_each do |adjustment|
      # Account for possible invalid data
      next if adjustment.source.nil?
      adjustment.source.update_column(:cost, adjustment.amount)
      adjustment.destroy!
    end

    # Tax adjustments have their sources altered
    Spree::Adjustment.where(:originator_type => "Spree::TaxRate").find_each do |adjustment|
      adjustment.source_id = adjustment.originator_id
      adjustment.source_type = "Spree::TaxRate"
      adjustment.save!
    end

    # This bit below needs to be removed, but we will have to do something similar for migrating the
    # originator fields on OFN fees.
    # This whole migration needs to be moved prior to the others that change the columns...

    # Promotion adjustments have their source altered also
    Spree::Adjustment.where(:originator_type => "Spree::PromotionAction").find_each do |adjustment|
      next if adjustment.originator.nil?
      adjustment.source = adjustment.originator
      begin
        if adjustment.source.calculator_type == "Spree::Calculator::FreeShipping"
          # Previously this was a Spree::Promotion::Actions::CreateAdjustment
          # And it had a calculator to work out FreeShipping
          # In Spree 2.2, the "calculator" is now the action itself.
          adjustment.source.becomes(Spree::Promotion::Actions::FreeShipping)
        end
      rescue
        # Fail silently. This is primarily in instances where the calculator no longer exists
      end

      adjustment.save!
    end
  end
end
