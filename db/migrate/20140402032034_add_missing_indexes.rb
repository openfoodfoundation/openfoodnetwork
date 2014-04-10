class AddMissingIndexes < ActiveRecord::Migration
  def change
    add_index :adjustment_metadata, :enterprise_id

    add_index :carts, :user_id

    add_index :coordinator_fees, :order_cycle_id
    add_index :coordinator_fees, :enterprise_fee_id

    add_index :distributors_payment_methods, :distributor_id
    add_index :distributors_payment_methods, :payment_method_id

    add_index :enterprise_fees, :enterprise_id

    add_index :enterprise_groups_enterprises, :enterprise_group_id
    add_index :enterprise_groups_enterprises, :enterprise_id

    add_index :enterprise_roles, :user_id
    add_index :enterprise_roles, :enterprise_id

    add_index :enterprises, :address_id

    add_index :exchange_fees, :exchange_id
    add_index :exchange_fees, :enterprise_fee_id

    add_index :exchange_variants, :exchange_id
    add_index :exchange_variants, :variant_id

    add_index :exchanges, :order_cycle_id
    add_index :exchanges, :sender_id
    add_index :exchanges, :receiver_id
    add_index :exchanges, :payment_enterprise_id

    add_index :product_distributions, :product_id
    add_index :product_distributions, :distributor_id
    add_index :product_distributions, :enterprise_fee_id
  end
end
