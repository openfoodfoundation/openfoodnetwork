class Api::Admin::ShippingMethodSerializer < ActiveModel::Serializer
  attributes :id, :name, :tags

  def tags
    object.tag_list.map{ |t| { text: t } }
  end
end
