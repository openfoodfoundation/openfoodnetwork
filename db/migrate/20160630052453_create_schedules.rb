class CreateSchedules < ActiveRecord::Migration
  def change
    create_table :schedules do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
