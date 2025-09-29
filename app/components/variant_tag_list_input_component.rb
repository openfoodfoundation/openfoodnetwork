# frozen_string_literal: true

class VariantTagListInputComponent < ViewComponent::Base
  def initialize(name:, variant:, tag_list_input_component: TagListInputComponent,
                 placeholder: I18n.t("components.tag_list_input.default_placeholder"),
                 aria_label: nil)
    @tag_list_input_component = tag_list_input_component
    @variant = variant
    @name = name
    @tags = variant.tag_list
    @placeholder = placeholder
    @only_one = false
    @aria_label = aria_label
  end

  attr_reader :tag_list_input_component, :variant, :name, :tags, :placeholder, :only_one,
              :aria_label

  private

  def autocomplete_url
    "/admin/tag_rules/variant_tag_rules?enterprise_id=#{variant.supplier_id}"
  end
end
