module ActionView
  module Helpers
    module CaptureHelper
      def delete_content_for(name)
        @view_flow.set(name, nil)
      end
    end
  end
end
