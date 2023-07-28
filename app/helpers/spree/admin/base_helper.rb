# frozen_string_literal: true

module Spree
  module Admin
    module BaseHelper
      def field_container(model, method, options = {}, &)
        css_classes = options[:class].to_a
        css_classes << 'field'
        if error_message_on(model, method).present?
          css_classes << 'withError'
        end
        content_tag(:div,
                    capture(&),
                    class: css_classes.join(' '),
                    id: "#{model}_#{method}_field")
      end

      def error_message_on(object, method, _options = {})
        object = convert_to_model(object)
        obj = object.respond_to?(:errors) ? object : instance_variable_get("@#{object}")

        if obj && obj.errors[method].present?
          errors = obj.errors[method].map { |err| h(err) }.join('<br />').html_safe
          content_tag(:span, errors, class: 'formError')
        else
          ''
        end
      end

      def preference_field_tag(name, value, options)
        case options[:type]
        when :integer, :decimal
          number_field_tag(name, value, preference_field_options(options))
        when :boolean
          hidden_field_tag(name, 0) +
            check_box_tag(name, 1, value, preference_field_options(options))
        when :string
          text_field_tag(name, value, preference_field_options(options))
        when :password
          password_field_tag(name, value, preference_field_options(options))
        when :text
          text_area_tag(name, value, preference_field_options(options))
        when :file
          file_field_tag name, preference_field_options(options)
        else
          text_field_tag(name, value, preference_field_options(options))
        end
      end

      def preference_field_for(form, field, options, object)
        case options[:type]
        when :integer, :decimal
          form.number_field(field, preference_field_options(options))
        when :boolean
          form.check_box(field, preference_field_options(options))
        when :string
          preference_field_for_text_field(form, field, options, object)
        when :password
          form.password_field(field, preference_field_options(options))
        when :text
          form.text_area(field, preference_field_options(options))
        else
          form.text_field(field, preference_field_options(options))
        end
      end

      # Here we show a text field for all string fields except when the field name ends in
      # "_from_list", in that case we render a dropdown.
      # In this specific case, to render the dropdown, the object provided must have a method named
      # like "#{field}_values" that returns an array with the string options to be listed.
      def preference_field_for_text_field(form, field, options, object)
        if field.end_with?('_from_list') && object.respond_to?("#{field}_values")
          list_values = object.__send__("#{field}_values")
          selected_value = object.__send__(field)
          form.select(field, options_for_select(list_values, selected_value),
                      preference_field_options(options))
        else
          form.text_field(field, preference_field_options(options))
        end
      end

      def preference_field_options(options)
        field_options =
          case options[:type]
          when :integer
            { size: 10, class: 'input_integer', step: 1 }
          when :decimal
            # Allow any number of decimal places
            { size: 10, class: 'input_integer', step: :any }
          when :boolean
            {}
          when :string
            { size: 10, class: 'input_string fullwidth' }
          when :password
            { size: 10, class: 'password_string fullwidth' }
          when :text
            { rows: 15, cols: 85, class: 'fullwidth' }
          else
            { size: 10, class: 'input_string fullwidth' }
          end

        field_options.merge!(
          readonly: options[:readonly],
          disabled: options[:disabled],
          size: options[:size]
        )
      end

      # maps each preference to a hash containing the label and field html.
      # E.g. { :label => "<label>...", :field => "<select>..." }
      def preference_fields(object, form)
        return unless object.respond_to?(:preferences)

        object.preferences.keys.map { |key|
          preference_label = form.label("preferred_#{key}",
                                        Spree.t(key.to_s.gsub("_from_list", "")) + ": ").html_safe
          preference_field = preference_field_for(
            form,
            "preferred_#{key}",
            { type: object.preference_type(key) }, object
          ).html_safe
          { label: preference_label, field: preference_field }
        }
      end

      def link_to_add_fields(name, target, options = {})
        name = '' if options[:no_text]
        css_classes = options[:class] ? options[:class] + " spree_add_fields" : "spree_add_fields"
        link_to_with_icon('icon-plus',
                          name,
                          'javascript:',
                          data: { target: target },
                          class: css_classes)
      end

      # renders hidden field and link to remove record using nested_attributes
      # add support for options[:html], allowing additional HTML attributes
      def link_to_remove_fields(name, form, options = {})
        name = '' if options[:no_text]
        options[:class] = '' unless options[:class]
        options[:class] += 'no-text with-tip' if options[:no_text]

        html_options = { class: "remove_fields #{options[:class]}",
                         data: { action: 'remove' },
                         title: t(:remove) }
        html_options.merge!(options[:html]) if options.key? :html

        link_to_with_icon('icon-trash', name, '#', html_options) + form.hidden_field(:_destroy)
      end

      def spree_dom_id(record)
        dom_id(record, 'spree')
      end

      private

      def attribute_name_for(field_name)
        field_name.tr(' ', '_').downcase
      end
    end
  end
end
