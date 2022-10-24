module Enterprise::TagGrouping
  attr_writer :tag_groups, :default_tag_group

  def tag_groups
    return @tag_groups if @tag_groups

    rules = tag_rules.prioritised.reject(&:is_default)
    @tag_groups = rules.each_with_object([]) do |tag_rule, tag_groups|
      tag_group = find_match(tag_groups, tag_rule.preferred_customer_tags.
                             split(",").
                             map{ |t| { text: t } })
      if tag_group.rules.blank?
        tag_groups << tag_group
        tag_group.position = tag_groups.count
      end
      tag_group.rules << tag_rule
    end
  end

  def default_tag_group
    return @default_tag_group if @default_tag_group

    rules = tag_rules.prioritised.select(&:is_default)
    @default_tag_group = Enterprise::TagGroup.new([], rules)
  end

  private

  def find_match(tag_groups, tags)
    tag_groups.each do |tag_group|
      return tag_group if tag_group.tags.length == tags.length &&
                          (tag_group.tags & tags) == tag_group.tags
    end
    Enterprise::TagGroup.new(tags, [])
  end
end
