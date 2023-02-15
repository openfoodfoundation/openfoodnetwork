# frozen_string_literal: true

# RSpec matcher for IntegerArrayValidator
#
# Usage:
#
#     describe Post do
#       it { should validate_integer_array(:related_post_ids) }
#     end
RSpec::Matchers.define :validate_integer_array do |attribute|
  match do |instance|
    @instance, @attribute = instance, attribute

    invalid_format_message = 'must contain only valid integers'

    allow(instance).to receive(attribute) { [1, "2", "Not Integer", 3] }
    instance.valid?
    (instance.errors[attribute] || []).include?(invalid_format_message)
  end

  description do
    "validates :#{@attribute} is integer array"
  end

  failure_message do
    "expected #{@instance} to validate :#{@attribute} is integer array"
  end

  failure_message_when_negated do
    "expected #{@instance} not to validate :#{@attribute} is integer array"
  end
end
