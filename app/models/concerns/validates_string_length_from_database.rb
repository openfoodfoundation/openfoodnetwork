# frozen_string_literal: true

# Validates string/text columns against their database length limits.
# Decimal columns are excluded: validating them as a numericality magnitude
# cap (less_than: 10^precision/10^scale) rather than a length check produces
# "must be less than N" errors on legitimate values.

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
