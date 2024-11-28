class ChangeNullOnSemanticLinks < ActiveRecord::Migration[7.0]
  def change
    change_column_null :semantic_links, :subject_id, false
    change_column_null :semantic_links, :subject_type, false

    change_column_null :semantic_links, :variant_id, true
  end
end
