# frozen_string_literal: true

class ConfirmModalComponent < ModalComponent
  # @param controller_data_values [Array(Hash)] format: {<value-name-1>: value1, <value-name-2>: value2}
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
    controller_data_values: {}
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
    @controller_data_values = transform_values_for_controller(controller_data_values)
  end

  private

  def close_button_class
    "secondary"
  end

  def modal_attrs
    @modal_attrs ||= {
      id: @id,
      "data-controller": "modal #{@controller}",
      "data-action": "keyup@document->modal#closeIfEscapeKey",
      "data-#{@controller}-reflex-value": @reflex
    }.merge(@controller_data_values)
  end

  def transform_values_for_controller(values)
    values.transform_keys { |value_name| "data-#{@controller}-#{value_name}-value" }
  end
end
