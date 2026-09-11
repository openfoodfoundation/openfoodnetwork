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
      add_too_long_error(column) if validated_length_column?(column)
    end
  end

  # Whether a column is a string/text column with a length limit.
  def validated_length_column?(column)
    %i[string text].include?(column.type) &&
      !(column.respond_to?(:array) && column.array) &&
      !column.limit.nil?
  end

  def add_too_long_error(column)
    value = public_send(column.name)
    return unless value.is_a?(String)
    return if value.blank? || value.length <= column.limit

    errors.add(column.name, :too_long, count: column.limit)
  end
end
