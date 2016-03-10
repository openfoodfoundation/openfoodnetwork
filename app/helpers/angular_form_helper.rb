module AngularFormHelper
  def ng_options_for_select(container, angular_field=nil)
    return container if String === container

    container.map do |element|
      html_attributes = option_html_attributes(element)
      text, value = option_text_and_value(element).map { |item| item.to_s }
      %(<option value="#{ERB::Util.html_escape(value)}"#{html_attributes}>#{ERB::Util.html_escape(text)}</option>)
    end.join("\n").html_safe
  end

  def ng_options_from_collection_for_select(collection, value_method, text_method, angular_field)
    options = collection.map do |element|
      [element.send(text_method), element.send(value_method)]
    end

    ng_options_for_select(options, angular_field)
  end
end


class ActionView::Helpers::InstanceTag
  include AngularFormHelper
end
