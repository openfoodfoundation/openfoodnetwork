# frozen_string_literal: true

class AddUniqueIndexSenderIdAndOthersToExchanges < ActiveRecord::Migration[7.0]
  def change
    remove_index :exchanges, :sender_id, name: :index_exchanges_on_sender_id
    add_index(:exchanges, [:sender_id, :order_cycle_id, :receiver_id, :incoming],
              unique: true, name: :index_exchanges_on_sender_id)
  end
end
