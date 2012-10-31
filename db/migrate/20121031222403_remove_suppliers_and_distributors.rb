class RemoveSuppliersAndDistributors < ActiveRecord::Migration
  def up
    drop_table :suppliers
    drop_table :distributors
  end

  def down
    create_table "distributors" do |t|
      t.string   :name
      t.string   :contact
      t.string   :phone
      t.string   :email
      t.string   :pickup_times
      t.string   :url
      t.string   :abn
      t.string   :acn
      t.string   :description
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :pickup_address_id
      t.string   :next_collection_at
      t.text     :long_description
    end

    create_table "suppliers" do |t|
      t.string   :name
      t.string   :description
      t.string   :email
      t.string   :twitter
      t.string   :website
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :address_id
      t.text     :long_description
    end
  end
end
