class Api::Admin::CustomerSerializer < ActiveModel::Serializer
  attributes :id, :email, :enterprise_id, :user_id, :code, :tags, :tag_list

  def tag_list
    object.tag_list.join(",")
  end

  def tags
    object.tag_list.map do |tag|
      tag_rule_map = options[:tag_rule_mapping][tag]
      tag_rule_map || { text: tag, rules: nil }
    end
  end
end
