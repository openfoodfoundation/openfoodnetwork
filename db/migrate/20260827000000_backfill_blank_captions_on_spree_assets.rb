# frozen_string_literal: true

# A nil caption used to mean "never set", which made the product or variant name
# render as a fallback caption. Now that a blank caption is honoured as a
# deliberate "no caption", backfill the never-set ones so every asset carries an
# explicit value. Captions that were actually entered are left untouched.
class BackfillBlankCaptionsOnSpreeAssets < ActiveRecord::Migration[7.2]
  class Asset < ActiveRecord::Base
    self.table_name = "spree_assets"
    self.inheritance_column = :_type_disabled
  end

  def up
    Asset.unscoped.where(caption: nil).in_batches do |assets|
      assets.update_all(caption: "")
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
