# frozen_string_literal: true

class ConfirmModalComponent < ModalComponent
  def initialize(id:, confirm_actions: nil, controllers: nil)
    super(id: id, close_button: true)
    @confirm_actions = confirm_actions
    @controllers = controllers
  end

  private

  def close_button_class
    "secondary"
  end
end
