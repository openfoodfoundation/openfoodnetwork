module RablHelper
  # See https://github.com/nesquena/rabl/issues/231
  # Allows us to test RABL views using URL helpers
  class FakeContext
    include Singleton
    include Rails.application.routes.url_helpers
    include Sprockets::Helpers::RailsHelper
    include Sprockets::Helpers::IsolatedHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::AssetTagHelper
  end
end
