# frozen_string_literal: true

require 'active_support/concern'

# This concern is used to duplicate the associations distributors and distributor_ids
#   across payment method and gateway
#   this fixes the inheritance problem https://github.com/openfoodfoundation/openfoodnetwork/issues/2781
module PaymentMethodDistributors
  extend ActiveSupport::Concern

  included do
    has_many :distributor_payment_methods, dependent: :destroy
    has_many :distributors, through: :distributor_payment_methods,
                            class_name: 'Enterprise',
                            foreign_key: 'distributor_id'
  end
end
