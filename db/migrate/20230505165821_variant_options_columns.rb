class VariantOptionsColumns < ActiveRecord::Migration[7.0]
  def up
    add_column :spree_variants, :variant_unit, :string
    add_column :spree_variants, :unit_presentation, :string
    add_column :spree_line_items, :unit_presentation, :string

    migrate_variant_unit
    migrate_variant_presentation
    migrate_line_item_presentation
  end

  def down
    remove_column :spree_variants, :variant_unit
    remove_column :spree_variants, :unit_presentation
    remove_column :spree_line_items, :unit_presentation
  end

  # Migrates variant's product's variant_unit value onto variant
  #
  # Spree::Variant.includes(:product).each do |variant|
  #   variant.update_columns(variant_unit: variant.product.variant_unit)
  # end
  def migrate_variant_unit
    ActiveRecord::Base.connection.execute(<<-SQL
      UPDATE spree_variants
      SET variant_unit = product.variant_unit
      FROM spree_products AS product
      WHERE spree_variants.product_id = product.id
    SQL
    )
  end

  # Migrates the variants' option_value's presentation onto the variant's unit_presentation
  #
  # Spree::Variant.includes(:option_values: :option_type).each do |variant|
  #   variant.update_columns(unit_presentation: variant.option_values.first.presentation)
  # end
  def migrate_variant_presentation
    ActiveRecord::Base.connection.execute(<<-SQL
      UPDATE spree_variants
      SET unit_presentation = option_values.presentation
      FROM (
        SELECT 
          DISTINCT ON (spree_option_values_variants.variant_id) variant_id,
          spree_option_values.presentation AS presentation
        FROM spree_option_values_variants
          LEFT JOIN spree_option_values ON spree_option_values.id = spree_option_values_variants.option_value_id
      ) option_values
      WHERE spree_variants.id = option_values.variant_id
    SQL
    )
  end

  # Migrates the line_items' option_value's presentation onto the line_items's unit_presentation
  #
  # Spree::LineItem.includes(:option_values: :option_type).each do |line_item|
  #   line_item.update_columns(unit_presentation: line_item.option_values.first.presentation)
  # end
  def migrate_line_item_presentation
    ActiveRecord::Base.connection.execute(<<-SQL
      UPDATE spree_line_items
      SET unit_presentation = option_values.presentation
      FROM (
        SELECT 
          DISTINCT ON (spree_option_values_line_items.line_item_id) line_item_id,
          spree_option_values.presentation AS presentation
        FROM spree_option_values_line_items
          LEFT JOIN spree_option_values ON spree_option_values.id = spree_option_values_line_items.option_value_id
      ) option_values
      WHERE spree_line_items.id = option_values.line_item_id
    SQL
    )
  end
end
