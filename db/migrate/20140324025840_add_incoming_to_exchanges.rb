class AddIncomingToExchanges < ActiveRecord::Migration
  class Exchange < ActiveRecord::Base
    belongs_to :order_cycle
    belongs_to :receiver, :class_name => 'Enterprise'

    def incoming?
      receiver == order_cycle.coordinator
    end
  end


  def up
    add_column :exchanges, :incoming, :boolean, null: false, default: false

    # Initialise based on whether the exchange is going to or coming
    # from the order cycle coordinator
    Exchange.all.each do |exchange|
      exchange.update_attribute :incoming, exchange.incoming?
    end
  end

  def down
    remove_column :exchanges, :incoming
  end
end
