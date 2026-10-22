# frozen_string_literal: true

# An info button which shows its content in a popover when clicked, like the price breakdown
# and the unit price explanation of the shopfront.
#
# It's the browser's popover, so it closes when clicking elsewhere or pressing Escape, and it
# shows on top of anything that would otherwise clip it, like the variant modal. CSS anchor
# positioning places it next to its button.
class InfoPopoverComponent < ViewComponent::Base
  PLACEMENTS = %w[top bottom].freeze

  def initialize(id:, label:, placement: "bottom", css_class: "")
    raise ArgumentError, "Unknown placement: #{placement}" unless placement.in?(PLACEMENTS)

    @id = id
    @label = label
    @placement = placement
    @css_class = css_class
  end

  private

  attr_reader :id, :label, :placement, :css_class

  # Each button needs an anchor name of its own for its popover to find it.
  def anchor_name
    "--#{id}"
  end
end
