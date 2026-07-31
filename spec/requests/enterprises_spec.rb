# frozen_string_literal: true

RSpec.describe EnterprisesController do
  describe "GET /enterprises/:permalink" do
    # `resources :enterprises` used to generate a `show` route which matched
    # first and raised, because the controller has no `show` action.
    it "redirects legacy enterprise URLs to the home page" do
      get "/enterprises/some-old-permalink"

      expect(response).to redirect_to("/")
    end
  end
end
