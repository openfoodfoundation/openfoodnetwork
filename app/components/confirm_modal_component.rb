# frozen_string_literal: true

class ConfirmModalComponent < ModalComponent
  # @param actions_alignment_class [String] possible classes: 'justify-space-around', 'justify-end'
  def initialize(
    id:,
    reflex: nil,
    controller: nil,
    message: nil,
    confirm_actions: nil,
    confirm_reflexes: nil,
    confirm_button_class: :primary,
    confirm_button_text: I18n.t('js.admin.modals.confirm'),
    cancel_button_text: I18n.t('js.admin.modals.cancel'),
    actions_alignment_class: 'justify-space-around'
  )
    super(id:, close_button: true)
    @confirm_actions = confirm_actions
    @reflex = reflex
    @confirm_reflexes = confirm_reflexes
    @controller = controller
    @message = message
    @confirm_button_class = confirm_button_class
    @confirm_button_text = confirm_button_text
    @cancel_button_text = cancel_button_text
    @actions_alignment_class = actions_alignment_class
  end

  private

  def close_button_class
    "secondary"
  end
end
