module OpenFoodNetwork
  module EmbeddedPagesHelper
    def on_embedded_page
      within_frame :frame do
        yield
      end
    end
  end
end
