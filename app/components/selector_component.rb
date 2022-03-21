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
    @state = :close
    @data = data
  end

  def toggle
    @state = @state == :open ? :close : :open
  end

  def close
    @state = :close
  end
end
