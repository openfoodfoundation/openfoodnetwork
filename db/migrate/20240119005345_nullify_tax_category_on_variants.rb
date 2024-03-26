class NullifyTaxCategoryOnVariants < ActiveRecord::Migration[7.0]
  def up
    say "Clearing any variant tax categories that have been deleted..."
    result = execute(<<-SQL
      UPDATE spree_variants
      SET tax_category_id = NULL
      WHERE tax_category_id IS NOT NULL
        AND tax_category_id NOT IN(
          SELECT id
          FROM spree_tax_categories
          WHERE deleted_at IS NULL
      )
    SQL
    )
    say "Done: #{result.cmd_status}"
  end
end
