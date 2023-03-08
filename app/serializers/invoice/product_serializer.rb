class Invoice::ProductSerializer < ActiveModel::Serializer
  attributes :name
  has_one :supplier, serializer: Invoice::EnterpriseSerializer
end