# frozen_string_literal: true

# Simply a table (for now)
class TableComponent < ViewComponent::Base
  def initialize(columns:, data: {})
    @columns = columns
    @data = data
  end

end
