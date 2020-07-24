# frozen_string_literal: true

module OrderManagement
  module Reports
    module BulkCoop
      class Permissions < ::Reports::Permissions
        def allowed_distributors
          @allowed_distributors ||= Enterprise.is_distributor.managed_by(user)
        end
      end
    end
  end
end
