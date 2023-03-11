# frozen_string_literal: true

class ContentScrubber < Rails::Html::PermitScrubber
  ALLOWED_TAGS = ["p", "b", "strong", "em", "i", "a", "u", "img"].freeze
  ALLOWED_ATTRIBUTES = ["href", "target", "src", "alt"].freeze

  def initialize
    super
    self.tags = ALLOWED_TAGS
    self.attributes = ALLOWED_ATTRIBUTES
  end

  def skip_node?(node)
    node.text?
  end
end
