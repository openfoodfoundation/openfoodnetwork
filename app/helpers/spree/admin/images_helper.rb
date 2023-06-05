# frozen_string_literal: true

module Spree
  module Admin
    module ImagesHelper
      def options_text_for(image)
        if image.viewable.is_a?(Spree::Variant)
          image.viewable.options_text
        else
          I18n.t(:all)
        end
      end
    end
  end
end
