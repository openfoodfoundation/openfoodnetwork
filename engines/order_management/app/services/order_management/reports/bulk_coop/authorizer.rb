# frozen_string_literal: true

module OrderManagement
  module Reports
    module BulkCoop
      class Authorizer < ::Reports::Authorizer
        def authorize!
          require_ids_allowed(parameters.distributor_ids, permissions.allowed_distributors)
        end
      end
    end
  end
end
