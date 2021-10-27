class MigrateCustomerNames < ActiveRecord::Migration[6.1]
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
  class Enterprise < ApplicationRecord; end
  module Spree
    class Preference < ApplicationRecord
      self.table_name = "spree_preferences"
      serialize :value
    end
  end

  def up
    migrate_customer_names_preferences!
  end

  def migrate_customer_names_preferences!
    Enterprise.where(sells: ["own", "any"]).find_each do |enterprise|
      next unless Spree::Preference.where(
        value: true, key: "/enterprise/show_customer_names_to_suppliers/#{enterprise.id}"
      ).exists?

      enterprise.update_columns(
        show_customer_names_to_suppliers: true
      )
    end
  end
end
