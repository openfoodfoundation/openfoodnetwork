# frozen_string_literal: true

class SelectorWithFilterComponent < SelectorComponent
  def initialize(title:, selected:, items:, data: {},
                 selected_items_i18n_key: 'components.selector_with_filter.selected_items')
    super(title: title, selected: selected, items: items, data: data)
    @selected_items = items.select { |item| @selected.include?(item[:value]) }
    @selected_items_i18n_key = selected_items_i18n_key
    @items = items
  end
end
