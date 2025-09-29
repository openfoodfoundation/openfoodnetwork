# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "/.well-known/" do
  describe "dfc/" do
    it "publishes our endpoints" do
      get "/.well-known/dfc/"

      expect(response).to have_http_status :ok
      expect(response.content_type).to eq "text/plain" # Should be JSON!
      expect(response.body).to include "ReadEnterprise"
    end
  end
end
