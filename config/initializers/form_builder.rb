#
# Allow some application_helper methods to be used in the scoped form_for manner
#
module ActionView
  module Helpers
    class FormBuilder
      def field_container(method, options = {}, &)
        @template.field_container(@object_name, method, options, &)
      end

      def error_message_on(method, options = {})
        @template.error_message_on(@object_name, method, objectify_options(options))
      end

      def text_field(method, options = {})
        render_field(:text_field, method, options)
      end

      def text_area(method, options = {})
        render_field(:text_area, method, options)
      end

      def email_field(method, options = {})
        render_field(:email_field, method, options)
      end

      def password_field(method, options = {})
        render_field(:password_field, method, options)
      end

      def search_field(method, options = {})
        render_field(:search_field, method, options)
      end

      def url_field(method, options = {})
        render_field(:url_field, method, options)
      end

      def phone_field(method, options = {})
        render_field(:phone_field, method, options)
      end

      private

      def render_field(helper, method, options)
        @template.public_send(
          helper,
          @object_name,
          method,
          objectify_options(with_maxlength(method, options))
        )
      end

      def with_maxlength(method, options)
        return options if options.key?(:maxlength) || options.key?("maxlength")
        return options unless object

        maxlength = maxlength_for(method)
        return options unless maxlength

        options.merge(maxlength: maxlength)
      end

      def maxlength_for(method)
        target = unwrap_decorated_object(object)
        maxlength_from_validators(target, method) || maxlength_from_database(target, method)
      end

      def maxlength_from_validators(target, method)
        return unless target.class.respond_to?(:validators_on)

        target.class.validators_on(method)
          .select { |validator| unconditional_length_validator?(validator) }
          .filter_map { |validator| maximum_from(validator) }
          .first
      end

      def maxlength_from_database(target, method)
        return unless target.class.respond_to?(:columns_hash)

        column = target.class.columns_hash[method.to_s]
        return unless column&.type == :string

        column.limit
      end

      def unconditional_length_validator?(validator)
        return false unless validator.is_a?(ActiveModel::Validations::LengthValidator)

        !validator.options.keys.intersect?(%i[if unless on])
      end

      def maximum_from(validator)
        options = validator.options
        return options[:maximum] if options.key?(:maximum)
        return options[:is] if options.key?(:is)

        range = options[:within] || options[:in]
        range.max if range.is_a?(Range) && range.finite?
      end

      def unwrap_decorated_object(object)
        return object.__getobj__ if object.respond_to?(:__getobj__)

        object
      end
    end
  end
end

ActionView::Base.field_error_proc = proc do |html_tag, _instance|
  ActionController::Base.helpers.content_tag(:span, html_tag, class: "field_with_errors")
end
