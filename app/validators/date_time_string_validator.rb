# frozen_string_literal: true

# Validates a datetime string with relaxed rules
#
# This uses ActiveSupport::TimeZone.parse behind the scenes.
#
# https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html#method-i-parse
#
# === Example
#
#   class Post
#     include ActiveModel::Validations
#
#     attr_accessor :published_at
#     validates :published_at, date_time_string: true
#   end
#
#   post = Post.new
#
#   post.published_at = nil
#   post.valid?                 # => true
#
#   post.published_at = ""
#   post.valid?                 # => true
#
#   post.published_at = []
#   post.valid?                 # => false
#   post.errors[:published_at]  # => ["must be a string"]
#
#   post.published_at = 1
#   post.valid?                 # => false
#   post.errors[:published_at]  # => ["must be a string"]
#
#   post.published_at = "2018-09-20 01:02:00 +10:00"
#   post.valid?                 # => true
#
#   post.published_at = "Not Valid"
#   post.valid?                 # => false
#   post.errors[:published_at]  # => ["must be valid"]
class DateTimeStringValidator < ActiveModel::EachValidator
  NOT_STRING_ERROR = I18n.t("validators.date_time_string_validator.not_string_error")
  INVALID_FORMAT_ERROR = I18n.t("validators.date_time_string_validator.invalid_format_error")

  def validate_each(record, attribute, value)
    return if value.nil? || value == ""

    validate_attribute_is_string(record, attribute, value)
    validate_attribute_is_datetime_string(record, attribute, value)
  end

  protected

  def validate_attribute_is_string(record, attribute, value)
    return if value.is_a?(String)

    record.errors.add(attribute, NOT_STRING_ERROR)
  end

  def validate_attribute_is_datetime_string(record, attribute, value)
    return unless value.is_a?(String)

    datetime = Time.zone.parse(value)
    record.errors.add(attribute, INVALID_FORMAT_ERROR) if datetime.blank?
  end
end
