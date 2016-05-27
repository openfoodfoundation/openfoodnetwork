class TagRule < ActiveRecord::Base
  belongs_to :enterprise

  preference :customer_tags, :string, default: ""

  validates :enterprise, presence: true

  attr_accessible :enterprise, :enterprise_id, :is_default, :priority
  attr_accessible :preferred_customer_tags

  scope :for, ->(enterprise) { where(enterprise_id: enterprise) }
  scope :prioritised, -> { order('priority ASC') }

  def self.mapping_for(enterprises)
    self.for(enterprises).inject({}) do |mapping, rule|
      rule.preferred_customer_tags.split(",").each do |tag|
        if mapping[tag]
          mapping[tag][:rules] += 1
        else
          mapping[tag] = { text: tag, rules: 1 }
        end
      end
      mapping
    end
  end
end
