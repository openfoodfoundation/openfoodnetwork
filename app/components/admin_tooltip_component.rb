# frozen_string_literal: true

class AdminTooltipComponent < ViewComponent::Base
  def initialize(text:, link_text:, placement: "top", link: "", link_class: "")
    @text = text
    @link_text = link_text
    @placement = placement
    @link = link
    @link_class = link_class
  end
end
