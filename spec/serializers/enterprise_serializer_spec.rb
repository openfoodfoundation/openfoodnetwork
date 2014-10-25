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
    serializer.to_json.should match taxon.id.to_s
  end

  it "will render urls" do
    serializer = Api::EnterpriseSerializer.new enterprise
    serializer.to_json.should match "map_005-hub.svg"
  end

  describe "visibility" do
    before do
      enterprise.stub(:visible).and_return true
    end

    it "is visible when confirmed" do
      enterprise.stub(:confirmed?).and_return true
      serializer = Api::EnterpriseSerializer.new enterprise
      expect(serializer.to_json).to match "\"visible\":true"
    end

    it "is not visible when unconfirmed" do
      enterprise.stub(:confirmed?).and_return false
      serializer = Api::EnterpriseSerializer.new enterprise
      expect(serializer.to_json).to match "\"visible\":false"
    end
  end
end
