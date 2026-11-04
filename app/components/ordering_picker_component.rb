# frozen_string_literal: true

# Select several options and drag them into the order you want.
# The value is submitted in that order as comma separated option values, eg. "3,1,2".
class OrderingPickerComponent < ViewComponent::Base
  # options: [[label, value], ...]
  def initialize(name:, id:, options:, value:, placeholder: "", **html_options)
    @name = name
    @id = id
    @options = options
    @value = value
    @placeholder = placeholder
    @html_options = html_options
  end

  private

  def data
    {
      controller: "tom-select",
      'tom-select-placeholder-value': @placeholder,
      'tom-select-options-value': tom_select_options.to_json,
      **@html_options.fetch(:data, {}),
    }
  end

  def html_options
    @html_options.except(:data)
  end

  def tom_select_options
    {
      plugins: {
        drag_drop: {},
        remove_button: {},
        checkbox_options: {
          checkedClassNames: ["ts-checked"],
          uncheckedClassNames: ["ts-unchecked"],
        },
      },
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
end
