#require 'spec_helper'

describe Api::EnterpriseSerializer do
  let(:enterprise) { create(:distributor_enterprise) }
  let(:taxon) { create(:taxon) }
  let(:data_class) { Struct.new(:earliest_closing_times, :active_distributors,
                                :distributed_taxons, :supplied_taxons,
                                :shipping_method_services, :relatives) }
  let(:data) { data_class.new({}, [], {}, {}, {}, {producers: [], distributors: []}) }

  it "serializes an enterprise" do
    serializer = Api::EnterpriseSerializer.new enterprise, data: data
    serializer.to_json.should match enterprise.name
  end

  it "will render urls" do
    serializer = Api::EnterpriseSerializer.new enterprise, data: data
    serializer.to_json.should match "map_005-hub.svg"
  end
end
