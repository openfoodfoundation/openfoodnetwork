# frozen_string_literal: true

module TableHelper
  # Selector for table row that has the given string
  def row_containing(value)
    find(:xpath, "(//tr[contains(., '#{value}')])")
  end
end
