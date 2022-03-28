# frozen_string_literal: true

class SuperSelectorComponent < SelectorComponent
  def initialize(title:, selected:, items:, data: {},
                 selected_items_i18n_key: 'components.super_selector.selected_items')
    super(title: title, selected: selected, items: items, data: data)
    @query = ""
    @selected_items = items.select { |item| @selected.include?(item[:value]) }
    @selected_items_i18n_key = selected_items_i18n_key

    filter_items
  end

  def search
    @query = element.value
    filter_items
  end

  def filter_items
    @filtered_items = if @query.empty?
                        @items
                      else
                        @items.select { |item| item[:label].downcase.include?(@query.downcase) }
                      end
  end
end
