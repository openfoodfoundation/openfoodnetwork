class OrderCycle < ActiveRecord::Base
  belongs_to :coordinator, :class_name => 'Enterprise'
  belongs_to :coordinator_admin_fee, :class_name => 'EnterpriseFee'
  belongs_to :coordinator_sales_fee, :class_name => 'EnterpriseFee'

  has_many :exchanges

  validates_presence_of :name
end
