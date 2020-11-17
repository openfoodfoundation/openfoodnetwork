# frozen_string_literal: true

module PermittedAttributes
  class PaymentMethod
    def initialize(params)
      @params = params
    end

    def call
      @params.permit(
        [:name, :description, :type, :active,
         :environment, :display_on, :tag_list,
         :preferred_enterprise_id, :preferred_server, :preferred_login, :preferred_password,
         :calculator_type, :preferred_api_key,
         :preferred_signature, :preferred_solution, :preferred_landing_page, :preferred_logourl,
         :preferred_test_mode, :calculator_type, { distributor_ids: [] },
         { calculator_attributes: PermittedAttributes::Calculator.attributes }]
      )
    end
  end
end
