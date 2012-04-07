module Spree
  class Distributor < ActiveRecord::Base
    set_table_name 'distributors'

    validates :name, :pickup_address, :presence => true
  end
end
