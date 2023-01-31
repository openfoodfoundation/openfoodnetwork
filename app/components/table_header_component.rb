# frozen_string_literal: true

class TableHeaderComponent < ViewComponentReflex::Component
  def initialize(columns:, sort:, data: {})
    super
    @columns = columns
    @sort = sort
    @data = data
  end
end
