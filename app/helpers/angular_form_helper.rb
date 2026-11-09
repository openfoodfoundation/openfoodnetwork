# frozen_string_literal: true

module AngularFormHelper
  def ng_options_for_select(container, _angular_field = nil)
    return container if container.is_a?(String)

    container.map do |element|
      html_attributes = option_html_attributes(element)
      text, value = option_text_and_value(element).map(&:to_s)
      %(<option value="#{ERB::Util.html_escape(value)}"\
        #{html_attributes}>#{ERB::Util.html_escape(text)}</option>)
    end.join("\n").html_safe # rubocop:disable Rails/OutputSafety
  end
end
