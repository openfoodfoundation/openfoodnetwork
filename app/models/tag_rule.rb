# frozen_string_literal: true

class TagRule < ApplicationRecord
  belongs_to :enterprise

  preference :customer_tags, :string, default: ""

  scope :for, ->(enterprise) { where(enterprise_id: enterprise) }
  scope :prioritised, -> { order('priority ASC') }
  scope :exclude_inventory, -> { where.not(type: "TagRule::FilterProducts") }
  scope :exclude_variant, -> { where.not(type: "TagRule::FilterVariants") }

  def self.mapping_for(enterprises)
    self.for(enterprises).each_with_object({}) do |rule, mapping|
      rule.preferred_customer_tags.split(",").each do |tag|
        if mapping[tag]
          mapping[tag][:rules] += 1
        else
          mapping[tag] = { text: tag, rules: 1 }
        end
      end
    end
  end

  def self.matching_variant_tag_rules_by_enterprises(enterprise_id, tag)
    rules = where(type: "TagRule::FilterVariants").for(enterprise_id)

    return [] if rules.empty?

    rules.select { |r| r.preferred_variant_tags =~ /#{tag}/ }
  end

  # The following method must be overriden in a concrete tagRule
  def tags
    raise NotImplementedError, 'please use concrete TagRule'
  end
end
