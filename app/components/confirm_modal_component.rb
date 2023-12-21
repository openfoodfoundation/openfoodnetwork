# frozen_string_literal: true

class ConfirmModalComponent < ModalComponent
  # @param confirm_reflex_data [Array(Hash)]
  #        format: {<value-name-1>: value1, <value-name-2>: value2}
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
    confirm_reflex_data: {},
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
    @confirm_reflex_data = transform_values_for_dataset(confirm_reflex_data)
    @actions_alignment_class = actions_alignment_class
  end

  private

  def close_button_class
    "secondary"
  end

  def confirm_button_attrs
    @confirm_button_attrs ||= {
      class: "button icon-plus #{@confirm_button_class}",
      type: 'button',
      value: @confirm_button_text,
      'data-action': @confirm_actions,
      'data-reflex': @confirm_reflexes,
      id: 'confirmModalButton'
    }.merge(@confirm_reflex_data)
  end

  def transform_values_for_dataset(values)
    values.transform_keys { |value_name| "data-#{value_name}" }
  end
end
