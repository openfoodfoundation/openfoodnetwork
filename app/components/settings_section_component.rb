# frozen_string_literal: true

# A titled group of related settings rows, see SettingsRowComponent.
class SettingsSectionComponent < ViewComponent::Base
  def initialize(id:, title:)
    @id = id
    @title = title
  end
end
