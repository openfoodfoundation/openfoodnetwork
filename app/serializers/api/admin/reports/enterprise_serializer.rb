module Api
  module Admin
    module Reports
      class EnterpriseSerializer < ActiveModel::Serializer
        attributes :id, :name

        has_one :address, serializer: Api::Admin::Reports::AddressSerializer
      end
    end
  end
end
