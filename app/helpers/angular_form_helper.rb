module AngularFormHelper
  def angular_options_for_select(container, angular_field=nil)
    return container if String === container

    container.map do |element|
      html_attributes = option_html_attributes(element)
      text, value = option_text_and_value(element).map { |item| item.to_s }
      selected_attribute = %Q( ng-selected="#{angular_field} == '#{value}'") if angular_field
      %(<option value="#{ERB::Util.html_escape(value)}"#{selected_attribute}#{html_attributes}>#{ERB::Util.html_escape(text)}</option>)
    end.join("\n").html_safe
  end
end

class ActionView::Helpers::InstanceTag
  include AngularFormHelper
end
