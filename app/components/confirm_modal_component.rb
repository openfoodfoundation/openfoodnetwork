# frozen_string_literal: true

class ConfirmModalComponent < ModalComponent
  def initialize(id:, confirm_actions: nil, controllers: nil, message: nil)
    super(id: id, close_button: true)
    @confirm_actions = confirm_actions
    @controllers = controllers
    @message = message
  end

  private

  def close_button_class
    "secondary"
  end
end
