#require 'spec_helper'

describe Api::EnterpriseSerializer do
  let(:enterprise) { create(:distributor_enterprise) }
  let(:taxon) { create(:taxon) }
  it "serializes an enterprise" do
    serializer = Api::EnterpriseSerializer.new enterprise 
    serializer.to_json.should match enterprise.name  
  end

  it "includes distributed taxons" do
    enterprise.stub(:distributed_taxons).and_return [taxon]
    serializer = Api::EnterpriseSerializer.new enterprise 
    serializer.to_json.should match taxon.name
  end
  
  it "will render urls" do
    serializer = Api::EnterpriseSerializer.new enterprise 
    serializer.to_json.should match "map-icon-hub.svg"
  end
end
