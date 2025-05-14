# frozen_string_literal: true

class TagListInputComponent < ViewComponent::Base
  # method in a "hidden_field" form helper and is the method used to get a list of tag on the model
  def initialize(form:, method:, tags:,
                 placeholder: I18n.t("components.tag_list_input.default_placeholder"),
                 aria_label: nil)
    @f = form
    @method = method
    @tags = tags
    @placeholder = placeholder
    @aria_label_option = aria_label ? { 'aria-label': aria_label } : {}
  end

  attr_reader :f, :method, :tags, :placeholder, :aria_label_option
end
