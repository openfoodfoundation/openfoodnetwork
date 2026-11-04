# frozen_string_literal: true

# A single setting with a title, an optional description and its controls as content.
class SettingsRowComponent < ViewComponent::Base
  def initialize(id:, title:, description: nil, **options)
    @id = id
    @title = title
    @description = description
    @options = options
  end
end
