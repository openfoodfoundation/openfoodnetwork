# frozen_string_literal: true

# Select several options and drag them into the order you want.
# The value is submitted in that order as comma separated option values, eg. "3,1,2".
class OrderingPickerComponent < ViewComponent::Base
  # options: [[label, value], ...]
  #   With a remote_url, only the selected options are needed. Others are searched on demand.
  def initialize(name:, id:, options:, value:, placeholder: "", remote_url: nil, **html_options)
    @name = name
    @id = id
    @options = options
    @value = value
    @placeholder = placeholder
    @remote_url = remote_url
    @html_options = html_options
  end

  private

  def data
    {
      controller: "tom-select",
      'tom-select-placeholder-value': @placeholder,
      'tom-select-options-value': tom_select_options.to_json,
      'tom-select-remote-url-value': @remote_url,
      **@html_options.fetch(:data, {}),
    }
  end

  def html_options
    @html_options.except(:data)
  end

  def tom_select_options
    {
      plugins:,
      maxItems: nil,
      delimiter: ",",
      allowEmptyOption: false,
      hideSelected: false,
      valueField: "value",
      labelField: "label",
      searchField: ["label"],
      options: @options.map { |label, value| { label:, value: value.to_s } },
    }
  end

  def plugins
    plugins = {
      drag_drop: {},
      remove_button: {},
      checkbox_options: {
        checkedClassNames: ["ts-checked"],
        uncheckedClassNames: ["ts-unchecked"],
      },
    }
    # Loads further pages of remote options while scrolling
    plugins[:virtual_scroll] = {} if @remote_url
    plugins
  end
end
