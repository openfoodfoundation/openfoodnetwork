# frozen_string_literal: true

class ConfirmModalComponent < ModalComponent
  def initialize(id:, confirm_actions: nil, reflex: nil, controller: nil, message: nil,
                 confirm_reflexes: nil)
    super(id: id, close_button: true)
    @confirm_actions = confirm_actions
    @reflex = reflex
    @confirm_reflexes = confirm_reflexes
    @controller = controller
    @message = message
  end

  private

  def close_button_class
    "secondary"
  end
end
