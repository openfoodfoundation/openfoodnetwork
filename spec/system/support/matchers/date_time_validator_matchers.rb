# frozen_string_literal: true

# RSpec matcher for DateTimeValidator
#
# Usage:
#
#     describe Post do
#       it { should validate_date_time_format_of(:start_at) }
#     end
RSpec::Matchers.define :validate_date_time_format_of do |attribute|
  match do |instance|
    @instance, @attribute = instance, attribute

    invalid_format_message = I18n.t("validators.date_time_string_validator.invalid_format_error")

    allow(instance).to receive(attribute) { "Invalid Format" }
    instance.valid?
    (instance.errors[attribute] || []).include?(invalid_format_message)
  end

  description do
    "validates :#{@attribute} has datetime format"
  end

  failure_message do
    "expected #{@instance} to validate format of :#{@attribute} is datetime"
  end

  failure_message_when_negated do
    "expected #{@instance} not to validate format of :#{@attribute} is datetime"
  end
end
