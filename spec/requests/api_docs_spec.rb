# frozen_string_literal: true

require 'spec_helper'

describe "API documentation", type: :request do
  it "shows the OFN API v1" do
    get rswag_ui_path
    expect(response).to redirect_to "/api-docs/index.html"

    get "/api-docs/index.html"
    expect(response).to have_http_status :success

    expect(response.body).to match "API V1"
  end

  it "can load the Swagger config" do
    get "/api-docs/v1/swagger.yaml"
    expect(response).to have_http_status :success
  end
end
