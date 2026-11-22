# frozen_string_literal: true

# Shops that let customers change their orders keep doing so under the new
# permissions: they get all three. Shops that didn't keep none, which is the
# column default.
class BackfillOrderChangePermissionsOnEnterprises < ActiveRecord::Migration[8.0]
  class Enterprise < ActiveRecord::Base
    self.table_name = "enterprises"
  end

  def up
    Enterprise.where(allow_order_changes: true).update_all(
      allow_order_additions: true,
      allow_order_removals: true,
      allow_order_cancellation: true,
    )
  end
end
