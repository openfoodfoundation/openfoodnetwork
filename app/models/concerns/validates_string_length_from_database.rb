# frozen_string_literal: true

# Validates that string columns do not exceed their database length limit.
#
# This is the server-side counterpart to the FormBuilder maxlength attribute
# injection: fields are limited in the browser, and this catches any over-limit
# value that still reaches the model. Only string/text columns are validated so
# that decimal columns (which historically broke under validates_lengths_from_database
# due to a numericality-with-precision check) are left untouched.
module ValidatesStringLengthFromDatabase
  extend ActiveSupport::Concern

  included do
    validate :validate_string_length_from_database
  end

  private

  def validate_string_length_from_database
    self.class.columns.each do |column|
      next unless %i[string text].include?(column.type)
      next if column.respond_to?(:array) && column.array

      limit = column.limit
      next if limit.nil?

      value = public_send(column.name)
      next if value.blank?
      next unless value.is_a?(String)
      next if value.length <= limit

      errors.add(column.name, :too_long, count: limit)
    end
  end
end
