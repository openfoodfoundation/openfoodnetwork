class DropProductDistributions < ActiveRecord::Migration[4.2]
  def up
    drop_table :product_distributions
  end

  def down
    create_table "product_distributions" do |t|
      t.integer  "product_id"
      t.integer  "distributor_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "enterprise_fee_id"
    end

    add_index "product_distributions",
              ["distributor_id"],
              name: "index_product_distributions_on_distributor_id"
    add_index "product_distributions",
              ["enterprise_fee_id"],
              name: "index_product_distributions_on_enterprise_fee_id"
    add_index "product_distributions",
              ["product_id"],
              name: "index_product_distributions_on_product_id"

    add_foreign_key "product_distributions",
                    "enterprise_fees",
                    name: "product_distributions_enterprise_fee_id_fk"
    add_foreign_key "product_distributions",
                    "enterprises",
                    name: "product_distributions_distributor_id_fk",
                    column: "distributor_id"
    add_foreign_key "product_distributions",
                    "spree_products",
                    name: "product_distributions_product_id_fk",
                    column: "product_id"
  end
end
