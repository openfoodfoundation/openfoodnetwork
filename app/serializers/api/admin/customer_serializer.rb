class Api::Admin::CustomerSerializer < ActiveModel::Serializer
  attributes :id, :email, :enterprise_id, :user_id, :code, :tags, :tag_list

  def tag_list
    object.tag_list.join(",")
  end

  def tags
    object.tag_list.map{ |t| { text: t } }
  end
end
