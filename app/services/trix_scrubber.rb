# frozen_string_literal: true

class TrixScrubber < Rails::Html::PermitScrubber
  ALLOWED_TAGS = ["p", "b", "strong", "em", "i", "a", "u", "br", "del", "h1", "blockquote", "pre",
                  "ul", "ol", "li"].freeze
  ALLOWED_ATTRIBUTES = ["href", "target", "src", "alt"].freeze

  def initialize
    super
    self.tags = ALLOWED_TAGS
    self.attributes = ALLOWED_ATTRIBUTES
  end
end
