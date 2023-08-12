# frozen_string_literal: true

class TagRule < ApplicationRecord
  self.belongs_to_required_by_default = false

  belongs_to :enterprise

  preference :customer_tags, :string, default: ""

  validates :enterprise, presence: true

  scope :for, ->(enterprise) { where(enterprise_id: enterprise) }
  scope :prioritised, -> { order('priority ASC') }

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
end
