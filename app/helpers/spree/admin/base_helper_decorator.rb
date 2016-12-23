module Spree
  module Admin
    module BaseHelper
      def preference_field_tag_with_files(name, value, options)
        if options[:type] == :file
          file_field_tag name, preference_field_options(options)
        else
          preference_field_tag_without_files name, value, options
        end
      end
      alias_method_chain :preference_field_tag, :files


      # Add support for options[:html], allowing additional HTML attributes
      def link_to_remove_fields(name, f, options = {})
        name = '' if options[:no_text]
        options[:class] = '' unless options[:class]
        options[:class] += 'no-text with-tip' if options[:no_text]

        html_options = {class: "remove_fields #{options[:class]}", data: {action: 'remove'}, title: t(:remove)}
        html_options.merge!(options[:html]) if options.key? :html

        link_to_with_icon('icon-trash', name, '#', html_options) + f.hidden_field(:_destroy)
      end

      def link_to_remove_fields_without_url(name, f, options = {})
        name = '' if options[:no_text]
        options[:class] = '' unless options[:class]
        options[:class] += 'no-text with-tip' if options[:no_text]

        html_options = {class: "remove_fields #{options[:class]}", data: {action: 'remove'}, title: t(:remove)}
        html_options.merge!(options[:html]) if options.key? :html

        link_to_with_icon('icon-trash', name, '#', html_options).gsub('href="#" ', '').html_safe +
          f.hidden_field(:_destroy)
      end
    end
  end
end
