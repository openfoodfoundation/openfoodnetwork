class Customer < ActiveRecord::Base
  belongs_to :enterprises
  attr_accessible :customer_code, :email
end
