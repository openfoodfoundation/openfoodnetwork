class Invoice::CustomerSerializer < ActiveModel::Serializer
  attributes :code, :email
end
