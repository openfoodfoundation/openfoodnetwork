class Api::Admin::ShippingMethodSerializer < ActiveModel::Serializer
  attributes :id, :name, :tag_list, :tags

  def tag_list
    object.tag_list.join(",")
  end

  def tags
    object.tag_list.map{ |t| { text: t } }
  end
end
