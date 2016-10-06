class Api::Admin::IndexStandingOrderSerializer < ActiveModel::Serializer
  attributes :id, :begins_at, :ends_at

  has_one :shop, serializer: Api::Admin::IdNameSerializer
  has_one :customer, serializer: Api::Admin::IdEmailSerializer # Remove IdEmailSerializer if no longer user here
  has_one :schedule, serializer: Api::Admin::IdNameSerializer
  has_one :payment_method, serializer: Api::Admin::IdNameSerializer
  has_one :shipping_method, serializer: Api::Admin::IdNameSerializer

  def begins_at
    object.begins_at.andand.strftime('%F')
  end

  def ends_at
    object.ends_at.andand.strftime('%F')
  end
end
