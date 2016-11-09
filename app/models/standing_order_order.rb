class StandingOrderOrder < ActiveRecord::Base
  belongs_to :order, class_name: 'Spree::Order', dependent: :destroy
  belongs_to :standing_order
end
