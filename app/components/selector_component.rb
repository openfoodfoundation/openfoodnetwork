# frozen_string_literal: true

class SelectorComponent < ViewComponentReflex::Component
  def initialize(title:, selected:, items:, data: {})
    super
    @title = title
    @items = items.map do |item|
      {
        label: item[:label],
        value: item[:value],
        selected: selected.include?(item[:value])
      }
    end
    @selected = selected
    @data = data
  end
end
