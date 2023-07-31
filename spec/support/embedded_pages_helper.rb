# frozen_string_literal: true

module OpenFoodNetwork
  module EmbeddedPagesHelper
    def on_embedded_page(&)
      within_frame(:frame, &)
    end
  end
end
