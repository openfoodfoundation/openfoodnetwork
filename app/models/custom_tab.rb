# frozen_string_literal: false

class CustomTab < ApplicationRecord
  belongs_to :enterprise

  validates :title, presence: true, length: { maximum: 20 }

  # Remove any unsupported HTML.
  def content=(html)
    super(HtmlSanitizer.sanitize(html))
  end
end
