module ActionController
  class Base
    def respond_with(*resources, &block)
      if self.class.mimes_for_respond_to.empty?
        raise "In order to use respond_with, first you need to declare the formats your " \
              "controller responds to in the class level"
      end

      if collector = retrieve_collector_from_mimes(&block)
        options = resources.size == 1 ? {} : resources.extract_options!

        # Fix spree issues #3531 and #2210 (patch provided by leiyangyou)
        if (defined_response = collector.response) && !Spree::BaseController.spree_responders[self.class.to_s.to_sym].try(:[], action_name.to_sym)
          if action = options.delete(:action)
            render action: action
          else
            defined_response.call
          end
        else
          # The action name is needed for processing
          options[:action_name] = action_name.to_sym
          # If responder is not specified then pass in Spree::Responder
          (options.delete(:responder) || Spree::Responder).call(self, resources, options)
        end
      end
    end
  end
end
