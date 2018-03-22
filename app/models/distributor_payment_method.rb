class DistributorPaymentMethod < ActiveRecord::Base
  self.table_name = "distributors_payment_methods" 
  belongs_to :payment_method, class_name: Spree::PaymentMethod
  belongs_to :distributor, class_name: Enterprise, touch: true
  belongs_to :creator, class_name: Spree::User
end
