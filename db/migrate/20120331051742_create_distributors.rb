class CreateDistributors < ActiveRecord::Migration
  def change
    create_table :distributors do |t|
      t.string :name
      t.string :contact
      t.string :phone
      t.string :email
      t.string :pickup_address
      t.string :pickup_times
      t.string :url
      t.string :abn
      t.string :acn
      t.string :description

      t.timestamps
    end
  end
end
