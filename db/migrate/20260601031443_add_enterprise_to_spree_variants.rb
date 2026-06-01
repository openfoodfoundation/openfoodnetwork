# frozen_string_literal: true

class AddEnterpriseToSpreeVariants < ActiveRecord::Migration[7.1]
  def change
    add_reference :spree_variants, :enterprise, null: true, foreign_key: true
  end
end
