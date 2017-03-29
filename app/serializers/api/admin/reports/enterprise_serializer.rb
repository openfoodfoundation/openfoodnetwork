class Api::Admin::Reports::EnterpriseSerializer < ActiveModel::Serializer
  attributes :id, :name, :address, :city, :postcode

  def address
    object.address.address1
  end

  def city
    object.address.city
  end

  def postcode
    object.address.zipcode
  end
end
