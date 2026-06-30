# frozen_string_literal: true

class WhatsThisTooltipComponent < TooltipComponent
  def initialize(text:, placement: "top")
    super(text: text, element_text: I18n.t('admin.whats_this'), placement: )
  end
end
