class AccountInvoice < ActiveRecord::Base
  belongs_to :user, class_name: "Spree::User"
  belongs_to :order, class_name: "Spree::Order"
  attr_accessible :user_id, :order_id, :issued_at, :month, :year
  has_many :billable_periods
end
