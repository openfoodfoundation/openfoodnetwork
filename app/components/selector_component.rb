# frozen_string_literal: true

class SelectorComponent < ViewComponentReflex::Component
  def initialize(title:, selected:, items:, data: {})
    @title = title
    @items = items.map do |item|
      {
        id: item,
        name: I18n.t("admin.products_page.columns_selector.#{item}"),
        selected: selected.include?(item)
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
