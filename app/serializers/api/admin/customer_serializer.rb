class Api::Admin::CustomerSerializer < ActiveModel::Serializer
  attributes :id, :email, :enterprise_id, :user_id, :code, :tags, :tag_list

  def tag_list
    object.tag_list.join(",")
  end

  def tags
    tag_rule_map = object.enterprise.rules_per_tag
    object.tag_list.map do |tag|
      { text: tag, rules: tag_rule_map[tag] }
    end
  end

end
