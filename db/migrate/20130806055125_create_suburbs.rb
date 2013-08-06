class CreateSuburbs < ActiveRecord::Migration
  def change
    create_table :suburbs do |t|
      t.string :name
      t.integer :postcode
      t.float :latitude
      t.float :longitude
      t.integer :state_id
    end
  end
end
