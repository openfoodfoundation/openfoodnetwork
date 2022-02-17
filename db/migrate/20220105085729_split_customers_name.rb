# frozen_string_literal: true

class SplitCustomersName < ActiveRecord::Migration[6.1]
  def up
    add_column :customers, :first_name, :string, null: false, default: ""
    add_column :customers, :last_name, :string, null: false, default: ""
  end

  def down
    remove_column :customers, :first_name
    remove_column :customers, :last_name
  end
end
