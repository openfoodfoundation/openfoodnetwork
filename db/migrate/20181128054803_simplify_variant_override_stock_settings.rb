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
    belongs_to :variant
    belongs_to :hub, class_name: "Enterprise"

    scope :with_count_on_hand, -> { where("count_on_hand IS NOT NULL") }
    scope :without_count_on_hand, -> { where(count_on_hand: nil) }
  end

  class Variant < ActiveRecord::Base
    self.table_name = "spree_variants"

    belongs_to :product

    def name
      namer = OpenFoodNetwork::OptionValueNamer.new(self)
      namer.name
    end
  end

  class Product < ActiveRecord::Base
    self.table_name = "spree_products"

    belongs_to :supplier, class_name: "Enterprise"
  end

  class Enterprise < ActiveRecord::Base; end

  def up
    CSV.open(csv_path, "w") do |csv|
      csv << csv_header_row

      update_use_producer_stock_settings_with_count_on_hand(csv)
      update_on_demand_with_count_on_hand(csv)
      update_limited_stock_without_count_on_hand(csv)
    end
  end

  def down
    CSV.foreach(csv_path, headers: true) do |row|
      VariantOverride.where(id: row["variant_override_id"])
        .update_all(on_demand: row["previous_on_demand"],
                    count_on_hand: row["previous_count_on_hand"])
    end
  end

  private

  def csv_path
    Rails.root.join("reports", "SimplifyVariantOverrideStockSettings-changed_variant_overrides.csv")
  end

  # When on_demand is nil but count_on_hand is set, force limited stock.
  def update_use_producer_stock_settings_with_count_on_hand(csv)
    variant_overrides = VariantOverride.where(on_demand: nil).with_count_on_hand
    update_variant_overrides_and_log(csv, variant_overrides) do |variant_override|
      variant_override.update_attributes!(on_demand: false)
    end
  end

  # Clear count_on_hand if forcing on demand.
  def update_on_demand_with_count_on_hand(csv)
    variant_overrides = VariantOverride.where(on_demand: true).with_count_on_hand
    update_variant_overrides_and_log(csv, variant_overrides) do |variant_override|
      variant_override.update_attributes!(count_on_hand: nil)
    end
  end

  # When on_demand is false but count on hand is not specified, set this to use producer stock
  # settings.
  def update_limited_stock_without_count_on_hand(csv)
    variant_overrides = VariantOverride.where(on_demand: false).without_count_on_hand
    update_variant_overrides_and_log(csv, variant_overrides) do |variant_override|
      variant_override.update_attributes!(on_demand: nil)
    end
  end

  def update_variant_overrides_and_log(csv, variant_overrides)
    variant_overrides.find_each do |variant_override|
      csv << variant_override_log_row(variant_override) do
        yield variant_override
      end
    end
  end

  def csv_header_row
    %w(
      variant_override_id
      distributor_name distributor_id
      producer_name producer_id
      product_name product_id
      variant_description variant_id
      previous_on_demand previous_count_on_hand
      updated_on_demand updated_count_on_hand
    )
  end

  def variant_override_log_row(variant_override)
    variant = variant_override.variant
    distributor = variant_override.hub
    product = variant.andand.product
    supplier = product.andand.supplier

    row = [
      variant_override.id,
      distributor.andand.name, distributor.andand.id,
      supplier.andand.name, supplier.andand.id,
      product.andand.name, product.andand.id,
      variant.andand.name, variant.andand.id,
      variant_override.on_demand, variant_override.count_on_hand
    ]

    yield variant_override

    row + [variant_override.on_demand, variant_override.count_on_hand]
  end
end
