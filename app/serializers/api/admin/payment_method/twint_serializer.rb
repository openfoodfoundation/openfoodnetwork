# frozen_string_literal: true

module Api
  module Admin
    module PaymentMethod
      class TwintSerializer < BaseSerializer
        attributes :preferred_enterprise_id
      end
    end
  end
end
