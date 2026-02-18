# frozen_string_literal: true

RSpec.describe 'Errors' do
  include ExceptionHelper

  shared_examples "returning a HTTP 404" do |path|
    it path do
      rails_respond_without_detailed_exceptions do
        get path
      end

      expect(response).to have_http_status(:not_found)
    end
  end

  it_behaves_like "returning a HTTP 404", "/nonexistent/path"
  it_behaves_like "returning a HTTP 404", "/nonexistent/path.jpg"
  it_behaves_like "returning a HTTP 404", "/nonexistent/path.xml"
end
