class UpdateReturnAdjustments < ActiveRecord::Migration[5.0]
  class Spree::Adjustment < ActiveRecord::Base
    belongs_to :source, polymorphic: true
  end

  def up
    Spree::Adjustment.where(source_type: 'Spree::ReturnAuthorization').update_all(
      "originator_id = source_id, originator_type = 'Spree::ReturnAuthorization', source_id = NULL, source_type = NULL"
    )
  end

  def down
    Spree::Adjustment.where(originator_type: 'Spree::ReturnAuthorization').update_all(
      "source_id = originator_id, source_type = 'Spree::ReturnAuthorization', originator_id = NULL, originator_type = NULL"
    )
  end
end
