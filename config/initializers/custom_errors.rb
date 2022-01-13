# This patch customises ActiveModel error messages, as previously handled by the custom_error_messages gem
# See: https://github.com/jeremydurham/custom-err-msg

module ActiveModel
  class Error
    def self.full_message(attribute, message, base)
      return message if attribute == :base

      attr_name = attribute.to_s.tr(".", "_").humanize
      attr_name = base.class.human_attribute_name(attribute, {
        default: attr_name,
        base: base,
      })

      if message.start_with?("^")
        I18n.t("errors.format.full_message", default: "%{message}", message: message[1..-1], attribute: attr_name)
      else
        I18n.t("errors.format", default: "%{attribute} %{message}", message: message, attribute: attr_name)
      end
    end
  end
end
