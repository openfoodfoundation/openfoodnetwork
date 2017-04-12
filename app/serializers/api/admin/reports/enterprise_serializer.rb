class Api::Admin::Reports::EnterpriseSerializer < ActiveModel::Serializer
  attributes :id, :name

  has_one :address, serializer: Api::Admin::Reports::AddressSerializer
end
