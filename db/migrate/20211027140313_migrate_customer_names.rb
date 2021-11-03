class MigrateCustomerNames < ActiveRecord::Migration[6.1]
  class Enterprise < ActiveRecord::Base
    scope :showing_customer_names, -> do
      joins(
        <<-SQL
          JOIN spree_preferences ON (
            value LIKE '--- true\n%'
            AND spree_preferences.key = CONCAT('/enterprise/show_customer_names_to_suppliers/', enterprises.id)
          )
        SQL
      )
    end
  end

  def up
    migrate_customer_names_preferences!
  end

  def migrate_customer_names_preferences!
    Enterprise.showing_customer_names.update_all(show_customer_names_to_suppliers: true)
  end
end
