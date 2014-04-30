require 'spec_helper'

describe ProducersController do
  it "gets all active producers" do
    Enterprise.stub_chain(:is_primary_producer, :visible)
    Enterprise.should_receive(:is_primary_producer)
    get :index
  end
end
