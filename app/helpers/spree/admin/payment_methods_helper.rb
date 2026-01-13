# frozen_string_literal: true

module Spree
  module Admin
    module PaymentMethodsHelper
      def payment_method_type_name(class_name)
        scope = "spree.admin.payment_methods.providers"
        key = class_name.demodulize.downcase

        I18n.t(key, scope:)
      end
    end
  end
end
