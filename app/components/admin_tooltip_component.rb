# frozen_string_literal: true

class AdminTooltipComponent < ViewComponent::Base
  def initialize(text:, link_text:, placement: "top", link: "", link_class: "",
                 no_link_element: false )
    @text = text
    @link_text = link_text
    @placement = placement
    @link = link
    @link_class = link_class
    @no_link_element = no_link_element
  end
end
