# frozen_string_literal: true

module OpenFoodNetwork
  module EmbeddedPagesHelper
    def on_embedded_page(&block)
      within_frame :frame, &block
    end
  end
end
