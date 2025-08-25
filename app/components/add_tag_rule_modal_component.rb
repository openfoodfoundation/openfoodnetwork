# frozen_string_literal: true

class AddTagRuleModalComponent < ModalComponent
  def initialize(id:, tag_rule_types:, current_index:, div_id:, is_default: false,
                 customer_tag: "", hidden_field_customer_tag_options: {} )
    super

    @close_button = false
    @modal_class = "tiny"

    @tag_rule_types = tag_rule_types
    @current_index = current_index
    @div_id = div_id
    @is_default = is_default
    @customer_tag = customer_tag
    @hidden_field_customer_tag_options = hidden_field_customer_tag_options
  end

  attr_reader :tag_rule_types, :current_index, :div_id, :is_default, :customer_tag,
              :hidden_field_customer_tag_options
end
