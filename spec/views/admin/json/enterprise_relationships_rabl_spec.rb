require 'spec_helper'

describe "admin/json/_enterprise_relationships.json.rabl" do
  let(:parent) { create(:enterprise) }
  let(:child) { create(:enterprise) }
  let(:enterprise_relationship) { create(:enterprise_relationship, parent: parent, child: child) }
  let(:render) { Rabl.render([enterprise_relationship], 'admin/json/enterprise_relationships', view_path: 'app/views', scope: RablHelper::FakeContext.instance) }

  it "renders a list of enterprise relationships" do
    render.should have_json_type(Array).at_path ''
    render.should have_json_type(Object).at_path '0'
  end

  it "renders enterprise ids" do
    render.should be_json_eql(parent.id).at_path '0/parent_id'
    render.should be_json_eql(child.id).at_path '0/child_id'
  end

  it "renders enterprise names" do
    render.should be_json_eql(parent.name.to_json).at_path '0/parent_name'
    render.should be_json_eql(child.name.to_json).at_path '0/child_name'
  end
end
