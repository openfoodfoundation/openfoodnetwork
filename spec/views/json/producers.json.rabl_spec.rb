require 'spec_helper'

describe 'json/_producers.json.rabl' do
  let!(:producer) { create(:supplier_enterprise) } 
  let(:render) { Rabl.render([producer], 'json/producers', view_path: 'app/views', scope: RablHelper::FakeContext.instance) }
  
  pending "renders a list of producers" do
    expect(render).to have_json_type(Array).at_path ''
    expect(render).to have_json_type(Object).at_path '0'
  end

  pending "renders names" do
    expect(render).to be_json_eql(producer.name.to_json).at_path '0/name'
  end
end
