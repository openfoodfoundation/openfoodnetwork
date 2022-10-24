# frozen_string_literal: true

class TagRulesReflex < ApplicationReflex
  def add_new_tag
    enterprise = Enterprise.dirty(enterprise_id, cache_namespace: session.id) || Enterprise.find(enterprise_id)
    tag_group = Enterprise::TagGroup.new([], [], enterprise.tag_groups.count + 1)
    enterprise.tag_groups << tag_group
    enterprise.save_dirty(cache_namespace: session.id)

    morph_tag_rules_with enterprise
  end

  # def add_new_rule_to
  #   enterprise = dirty_enterprise(enterprise_id) || Enterprise.find(enterprise_id)
  #
  #   tag_rule = enterprise.tag_rules.build(type: type)
  #   if element.dataset["default"]
  #     tag_rule.is_default = true
  #     enterprise.default_tag_group.rules << tag_rule
  #   else
  #     position = element.dataset["tag-group-position"]
  #     enterprise.tag_groups[position].rules << tag_rule
  #   end
  #
  #   store_dirty_enterprise_to_cache(enterprise)
  #
  #   morph_tag_rules_with enterprise
  # end
  #
  # def delete_tag_rule
  #   enterprise = Enterprise.find(enterprise_id)
  #   enterprise.tag_rules.delete(element.dataset["tag-rule-id"])
  #   morph_tag_rules_with enterprise
  # end

  private

  def enterprise_id
    element.dataset["enterprise-id"]
  end

  def morph_tag_rules_with(enterprise)
    morph "[data-controller='tag-rules']",
          render(
            partial: "admin/enterprises/form/tag_rules",
            locals: { enterprise: enterprise }
          )
  end
end
