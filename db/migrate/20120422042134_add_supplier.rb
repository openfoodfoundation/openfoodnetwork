class AddSupplier < ActiveRecord::Migration
  def change
    create_table :suppliers do |t|
      t.string :name
      t.string :description
      t.string :url
      t.string :email
      t.string :twitter
      t.string :website

      t.integer :address_id

      t.timestamps
    end
  end
end
