# frozen_string_literal: true

RSpec.describe Api::V0::BaseController do
  render_views
  controller(Api::V0::BaseController) do
    skip_authorization_check only: :index

    def index
      render plain: { "products" => [] }.to_json
    end

    def spree_current_user; end
  end

  context "signed in as a user using an authentication extension" do
    before do
      allow(controller).to receive_messages spree_current_user:
                                              double(email: "ofn@example.com")
    end

    it "can make a request" do
      api_get :index
      expect(json_response).to eq( "products" => [] )
      expect(response).to have_http_status(:ok)
    end
  end

  context "can make an anonymous request to the API" do
    it "without an API key" do
      api_get :index
      expect(json_response["products"]).to eq []
      expect(response).to have_http_status(:ok)
    end
  end

  context "cannot make a request to the API" do
    it "with an invalid API key" do
      request.headers["X-Spree-Token"] = "fake_key"
      get :index, params: {}
      expect(json_response).to eq( "error" => "Invalid API key (fake_key) specified." )
      expect(response).to have_http_status(:unauthorized)
    end

    it "using an invalid token param" do
      get :index, params: { token: "fake_key" }
      expect(json_response).to eq( "error" => "Invalid API key (fake_key) specified." )
    end
  end

  it 'handles exceptions' do
    expect(subject).to receive(:authenticate_user).and_return(true)
    expect(subject).to receive(:index).and_raise(Exception.new("no joy"))
    get :index
    expect(json_response).to eq( "exception" => "no joy" )
  end

  it 'handles record not found' do
    expect(subject).to receive(:authenticate_user).and_return(true)
    expect(subject).to receive(:index).and_raise(ActiveRecord::RecordNotFound.new)
    get :index
    expect(json_response)
      .to eq( "error" => "The resource you were looking for could not be found." )
    expect(response).to have_http_status(:not_found)
  end
end
