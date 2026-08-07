# frozen_string_literal: true

# Available placement are the same as the ones provided
# by app/webpacker/controllers/tooltip_controller.js :
#  - available placements: 'top', 'right', 'bottom', 'left'
#  - placement options: '-start', '-end', ie right-start or 'bottom-end'
#
class TooltipComponent < ViewComponent::Base
  def initialize(text:, element_text:, placement: "top", link: "", element_class: "")
    @text = text
    @element_text = element_text
    @placement = placement
    @link = link
    @element_class = "tooltip-element #{element_class}"
  end
end
