# frozen_string_literal: true

class AdminTooltipComponent < ViewComponent::Base
  def initialize(text:, element_text:, placement: "top", link: "", element_class: "")
    @text = text
    @element_text = element_text
    @placement = placement
    @link = link
    @element_class = "tooltip-element #{element_class}"
  end
end
