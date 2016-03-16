class TagRule < ActiveRecord::Base
  attr_accessor :subject, :context

  belongs_to :enterprise

  preference :customer_tags, :string, default: ""

  validates :enterprise, presence: true

  attr_accessible :enterprise, :enterprise_id, :preferred_customer_tags

  def set_context(subject, context)
    @subject = subject
    @context = context
  end

  def apply
    apply! if relevant?
  end

  private

  def relevant?
    return false unless subject.class == subject_class
    return false unless customer_tags_match?
    if respond_to?(:additional_requirements_met?, true)
      return false unless additional_requirements_met?
    end
    true
  end

  def customer_tags_match?
    context_customer_tags = context.andand[:customer].andand.tag_list || []
    preferred_tags = preferred_customer_tags.split(",")
    ( context_customer_tags & preferred_tags ).any?
  end
end
