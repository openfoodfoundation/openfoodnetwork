module Spree
  module Admin
    module BaseHelper
      # Add url option to pass in link URL
      def link_to_remove_fields(name, f, options = {})
        name = '' if options[:no_text]
        options[:class] = '' unless options[:class]
        options[:class] += 'no-text with-tip' if options[:no_text]

        url = if f.object.persisted?
                options[:url] || [:admin, f.object]
              else
                '#'
              end

        link_to_with_icon('icon-trash', name, url, :class => "remove_fields #{options[:class]}", :data => {:action => 'remove'}, :title => t(:remove)) + f.hidden_field(:_destroy)
      end
    end
  end
end
