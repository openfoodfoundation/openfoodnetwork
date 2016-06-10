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
    end
  end
end
