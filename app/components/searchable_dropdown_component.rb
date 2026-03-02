# frozen_string_literal: true

class SearchableDropdownComponent < ViewComponent::Base
  MINIMUM_OPTIONS_FOR_SEARCH_FIELD = 11 # at least 11 options are required for the search field

  def initialize(
    name:,
    options:,
    selected_option:,
    form: nil,
    placeholder_value: '',
    include_blank: false,
    aria_label: '',
    multiple: false,
    remote_url: nil,
    other_attrs: {}
  )
    @f = form
    @name = name
    @options = options
    @selected_option = selected_option
    @placeholder_value = placeholder_value
    @include_blank = include_blank
    @aria_label = aria_label
    @multiple = multiple
    @remote_url = remote_url
    @other_attrs = other_attrs
  end

  private

  attr_reader :f, :name, :options, :selected_option, :placeholder_value, :include_blank,
              :aria_label, :multiple, :remote_url, :other_attrs

  def classes
    "fullwidth #{'no-input' if remove_search_plugin?}"
  end

  def data
    {
      controller: "tom-select",
      'tom-select-placeholder-value': placeholder_value,
      'tom-select-options-value': tom_select_options_value,
      'tom-select-remote-url-value': remote_url,
    }
  end

  def tom_select_options_value
    plugins = []
    plugins << 'virtual_scroll' if @remote_url.present?
    plugins << 'dropdown_input' unless remove_search_plugin?
    plugins << 'remove_button' if multiple

    {
      plugins:,
      maxItems: multiple ? nil : 1,
    }
  end

  def uses_form_builder?
    f.present?
  end

  def remove_search_plugin?
    # Remove the search plugin when:
    # - the select is multiple (it already includes a search field), or
    # - there is no remote URL and the options are below the search threshold
    @remove_search_plugin ||= multiple ||
                              (@remote_url.nil? && options.count < MINIMUM_OPTIONS_FOR_SEARCH_FIELD)
  end
end
