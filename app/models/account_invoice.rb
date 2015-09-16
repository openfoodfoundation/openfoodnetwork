class AccountInvoice < ActiveRecord::Base
  belongs_to :user
  belongs_to :order
  attr_accessible :issued_at, :month, :year
end
