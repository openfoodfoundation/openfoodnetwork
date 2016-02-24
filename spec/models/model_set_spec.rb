require 'spec_helper'

describe ModelSet do
  describe "updating" do
    it "creates new models" do
      attrs = {collection_attributes: {'1' => {name: 's1'},
                                       '2' => {name: 's2'}}}

      ms = ModelSet.new(EnterpriseRelationshipPermission, EnterpriseRelationshipPermission.all, attrs)

      expect { ms.save }.to change(EnterpriseRelationshipPermission, :count).by(2)

      EnterpriseRelationshipPermission.where(name: ['s1', 's2']).count.should == 2
    end


    it "updates existing models" do
      e1 = create(:enterprise_group)
      e2 = create(:enterprise_group)

      attrs = {collection_attributes: {'1' => {id: e1.id, name: 'e1zz', description: 'foo'},
                                       '2' => {id: e2.id, name: 'e2yy', description: 'bar'}}}

      ms = ModelSet.new(EnterpriseGroup, EnterpriseGroup.all, attrs)

      expect { ms.save }.to change(EnterpriseGroup, :count).by(0)

      EnterpriseGroup.where(name: ['e1zz', 'e2yy']).count.should == 2
    end


    it "destroys deleted models" do
      e1 = create(:enterprise)
      e2 = create(:enterprise)

      attrs = {collection_attributes: {'1' => {id: e1.id, name: 'deleteme'},
                                       '2' => {id: e2.id, name: 'e2'}}}

      ms = ModelSet.new(Enterprise, Enterprise.all, attrs, nil,
                        proc { |attrs| attrs['name'] == 'deleteme' })

      expect { ms.save }.to change(Enterprise, :count).by(-1)

      Enterprise.where(id: e1.id).should be_empty
      Enterprise.where(id: e2.id).should be_present
    end


    it "ignores deletable new records" do
      attrs = {collection_attributes: {'1' => {name: 'deleteme'}}}

      ms = ModelSet.new(Enterprise, Enterprise.all, attrs, nil,
                        proc { |attrs| attrs['name'] == 'deleteme' })

      expect { ms.save }.to change(Enterprise, :count).by(0)
    end
  end
end
