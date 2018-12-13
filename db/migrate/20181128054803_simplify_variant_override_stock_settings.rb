# This simplifies variant overrides to have only the following combinations:
#
#    on_demand | count_on_hand
#   -----------+---------------
#    true      | nil
#    false     | set
#    nil       | nil
#
# Refer to the table {here}[https://github.com/openfoodfoundation/openfoodnetwork/issues/3067] for
# the effect of different variant and variant override stock configurations.
#
# Furthermore, this will allow all existing variant overrides to satisfy the newly added model
# validation rules.
class SimplifyVariantOverrideStockSettings < ActiveRecord::Migration
  def up
    # When on_demand is nil but count_on_hand is set, force limited stock.
    VariantOverride.where(on_demand: nil).where("count_on_hand IS NOT NULL")
      .update_all(on_demand: false)

    # Clear count_on_hand if forcing on demand.
    VariantOverride.where(on_demand: true).update_all(count_on_hand: nil)

    # When on_demand is false but count on hand is not specified, set this to use producer stock
    # settings.
    VariantOverride.where(on_demand: false, count_on_hand: nil).update_all(on_demand: nil)
  end

  def down; end
end
