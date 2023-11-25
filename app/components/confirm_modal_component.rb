# frozen_string_literal: true

class ConfirmModalComponent < ModalComponent
  def initialize(
    id:,
    reflex: nil,
    controller: nil,
    message: nil,
    confirm_actions: nil,
    confirm_reflexes: nil,
    confirm_button_color: :primary,
    confirm_button_text: I18n.t('js.admin.modals.confirm'),
    cancel_button_text: I18n.t('js.admin.modals.cancel')
  )
    super(id:, close_button: true)
    @confirm_actions = confirm_actions
    @reflex = reflex
    @confirm_reflexes = confirm_reflexes
    @controller = controller
    @message = message
    @confirm_button_color = confirm_button_color
    @confirm_button_text = confirm_button_text
    @cancel_button_text = cancel_button_text
  end

  private

  def close_button_class
    "secondary"
  end
end
