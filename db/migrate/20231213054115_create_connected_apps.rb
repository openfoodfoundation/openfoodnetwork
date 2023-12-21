# frozen_string_literal: true

class CreateConnectedApps < ActiveRecord::Migration[7.0]
  def change
    create_table :connected_apps do |t|
      t.belongs_to :enterprise, foreign_key: true
      t.json :data

      t.timestamps
    end
  end
end
