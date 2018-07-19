module OpenFoodNetwork
  module EmbeddedPagesHelper
    def on_embedded_page
      expect(page).to have_selector "iframe"

      within_frame :frame do
        yield
      end
    end
  end
end
