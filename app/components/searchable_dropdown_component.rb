# frozen_string_literal: true

class SearchableDropdownComponent < ViewComponent::Base
  REMOVED_SEARCH_PLUGIN = { 'tom-select-options-value': '{ "plugins": [] }' }.freeze
  MINIMUM_OPTIONS_FOR_SEARCH_FIELD = 11 # at least 11 options are required for the search field

  def initialize(
    form:,
    name:,
    options:,
    selected_option:,
    placeholder_value:,
    include_blank: false,
    aria_label: '',
    other_attrs: {}
  )
    @f = form
    @name = name
    @options = options
    @selected_option = selected_option
    @placeholder_value = placeholder_value
    @include_blank = include_blank
    @aria_label = aria_label
    @other_attrs = other_attrs
  end

  private

  attr_reader :f, :name, :options, :selected_option, :placeholder_value, :include_blank,
              :aria_label, :other_attrs

  def classes
    "fullwidth #{'no-input' if remove_search_plugin?}"
  end

  def data
    {
      controller: "tom-select",
      'tom-select-placeholder-value': placeholder_value
    }.merge(remove_search_plugin? ? REMOVED_SEARCH_PLUGIN : {})
  end

  def remove_search_plugin?
    @remove_search_plugin ||= options.count < MINIMUM_OPTIONS_FOR_SEARCH_FIELD
  end
end
