class AddDeletedAtToReturnAuthorizations < ActiveRecord::Migration[5.0]
  def change
    add_column :spree_return_authorizations, :deleted_at, :datetime
  end
end
