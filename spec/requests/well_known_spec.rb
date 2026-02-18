# frozen_string_literal: true

RSpec.describe "/.well-known/" do
  describe "dfc/" do
    it "publishes our endpoints" do
      get "/.well-known/dfc/"

      expect(response).to have_http_status :ok
      expect(response.body).to include "ReadEnterprise"
      expect(response.content_type).to eq "application/json; charset=utf-8"
      expect(response.parsed_body.count).to eq 2
    end
  end
end
