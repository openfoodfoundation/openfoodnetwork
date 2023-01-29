# frozen_string_literal: true

class ModalComponent < ViewComponent::Base
  def initialize(id:, close_button: true)
    @id = id
    @close_button = close_button
  end

  private

  def close_button_class
    if namespace == "admin"
      "red"
    else
      "primary"
    end
  end

  def close_button?
    !!@close_button
  end

  def namespace
    helpers.controller_path.split("/").first
  end
end
