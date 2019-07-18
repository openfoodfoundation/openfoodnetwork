require 'spec_helper'

describe Spree::Api::BaseController do
  render_views
  controller(Spree::Api::BaseController) do
    def index
      render text: { "products" => [] }.to_json
    end

    def spree_current_user; end
  end

  context "signed in as a user using an authentication extension" do
    before do
      allow(controller).to receive_messages try_spree_current_user:
                                              double(email: "spree@example.com")
      Spree::Api::Config[:requires_authentication] = true
    end

    it "can make a request" do
      api_get :index
      expect(json_response).to eq( "products" => [] )
      expect(response.status).to eq(200)
    end
  end

  context "cannot make a request to the API" do
    it "without an API key" do
      api_get :index
      expect(json_response).to eq( "error" => "You must specify an API key." )
      expect(response.status).to eq(401)
    end

    it "with an invalid API key" do
      request.env["X-Spree-Token"] = "fake_key"
      get :index, {}
      expect(json_response).to eq( "error" => "Invalid API key (fake_key) specified." )
      expect(response.status).to eq(401)
    end

    it "using an invalid token param" do
      get :index, token: "fake_key"
      expect(json_response).to eq( "error" => "Invalid API key (fake_key) specified." )
    end
  end

  it 'handles exceptions' do
    expect(subject).to receive(:authenticate_user).and_return(true)
    expect(subject).to receive(:index).and_raise(Exception.new("no joy"))
    get :index, token: "fake_key"
    expect(json_response).to eq( "exception" => "no joy" )
  end

  it "maps symantec keys to nested_attributes keys" do
    klass = double(nested_attributes_options: { line_items: {},
                                                bill_address: {} })
    attributes = { 'line_items' => { id: 1 },
                   'bill_address' => { id: 2 },
                   'name' => 'test order' }

    mapped = subject.map_nested_attributes_keys(klass, attributes)
    expect(mapped.key?('line_items_attributes')).to be_truthy
    expect(mapped.key?('name')).to be_truthy
  end
end
