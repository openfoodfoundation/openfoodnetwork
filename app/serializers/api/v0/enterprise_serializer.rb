class Api::V0::EnterpriseSerializer < ActiveModel::Serializer
  attributes :id, :url, :name, :email, :website, :category
  attributes :description, :long_description

  has_one :address

  def url
    enterprise_url(object)
  end
end
