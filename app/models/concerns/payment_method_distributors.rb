# frozen_string_literal: true

require 'active_support/concern'

# This concern is used to duplicate the associations distributors and distributor_ids
#   across payment method and gateway
#   this fixes the inheritance problem https://github.com/openfoodfoundation/openfoodnetwork/issues/2781
module PaymentMethodDistributors
  extend ActiveSupport::Concern

  included do
    has_and_belongs_to_many :distributors, join_table: 'distributors_payment_methods',
                                           class_name: 'Enterprise',
                                           foreign_key: 'payment_method_id',
                                           association_foreign_key: 'distributor_id'
  end
end
