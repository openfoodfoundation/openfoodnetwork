# frozen_string_literal: true

class TagListInputComponent < ViewComponent::Base
  def initialize(name:, tags:,
                 placeholder: I18n.t("components.tag_list_input.default_placeholder"),
                 aria_label: nil)
    @name = name
    @tags = tags
    @placeholder = placeholder
    @aria_label_option = aria_label ? { 'aria-label': aria_label } : {}
  end

  attr_reader :name, :tags, :placeholder, :aria_label_option
end
