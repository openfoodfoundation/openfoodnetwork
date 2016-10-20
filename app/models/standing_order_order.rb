class StandingOrderOrder < ActiveRecord::Base
  belongs_to :order, class_name: 'Spree::Order'
  belongs_to :standing_order
end
