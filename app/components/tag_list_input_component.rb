# frozen_string_literal: true

class TagListInputComponent < ViewComponent::Base
  def initialize(name:, tags:,
                 placeholder: I18n.t("components.tag_list_input.default_placeholder"),
                 only_one: false,
                 aria_label: nil,
                 hidden_field_data_options: {},
                 autocomplete_url: "")
    @name = name
    @tags = tags
    @placeholder = placeholder
    @only_one = only_one
    @aria_label_option = aria_label ? { 'aria-label': aria_label } : {}
    @hidden_field_data_options = hidden_field_data_options
    @autocomplete_url = autocomplete_url
  end

  attr_reader :name, :tags, :placeholder, :only_one, :aria_label_option,
              :hidden_field_data_options, :autocomplete_url

  private

  def display
    return "none" if tags.length >= 1 && only_one == true

    "block"
  end
end
