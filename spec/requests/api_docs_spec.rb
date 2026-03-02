# frozen_string_literal: true

RSpec.describe "API documentation" do
  it "shows the OFN API v1" do
    get rswag_ui_path
    expect(response).to redirect_to "/api-docs/index.html"

    get "/api-docs/index.html"
    expect(response).to have_http_status :success

    expect(response.body).to match "API V1"
  end

  it "can load the Swagger config" do
    get "/api-docs/v1.yaml"
    expect(response).to have_http_status :success
  end
end
