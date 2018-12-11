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
  class VariantOverride < ActiveRecord::Base
    scope :with_count_on_hand, -> { where("count_on_hand IS NOT NULL") }
    scope :without_count_on_hand, -> { where(count_on_hand: nil) }
  end

  def up
    # When on_demand is nil but count_on_hand is set, force limited stock.
    VariantOverride.where(on_demand: nil).with_count_on_hand.find_each do |variant_override|
      variant_override.update_attributes!(on_demand: false)
    end

    # Clear count_on_hand if forcing on demand.
    VariantOverride.where(on_demand: true).with_count_on_hand.find_each do |variant_override|
      variant_override.update_attributes!(count_on_hand: nil)
    end

    # When on_demand is false but count on hand is not specified, set this to use producer stock
    # settings.
    VariantOverride.where(on_demand: false).without_count_on_hand.find_each do |variant_override|
      variant_override.update_attributes!(on_demand: nil)
    end
  end

  def down; end
end
