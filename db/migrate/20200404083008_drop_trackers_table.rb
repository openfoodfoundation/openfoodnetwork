class DropTrackersTable < ActiveRecord::Migration
  def up
    drop_table :spree_trackers
  end

  def down
    create_table :spree_trackers do |t|
      t.string     :environment
      t.string     :analytics_id
      t.boolean    :active,       :default => true
      t.timestamps
    end
  end
end
