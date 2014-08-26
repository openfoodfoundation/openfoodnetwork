require 'spec_helper'

describe EnterpriseRelationship do
  describe "scopes" do
    let(:e1)  { create(:enterprise, name: 'A') }
    let(:e2)  { create(:enterprise, name: 'B') }
    let(:e3)  { create(:enterprise, name: 'C') }

    it "sorts by parent, child enterprise name" do
      er1 = create(:enterprise_relationship, parent: e1, child: e3)
      er2 = create(:enterprise_relationship, parent: e2, child: e1)
      er3 = create(:enterprise_relationship, parent: e1, child: e2)

      EnterpriseRelationship.by_name.should == [er3, er1, er2]
    end

    describe "finding relationships involving some enterprises" do
      let!(:er) { create(:enterprise_relationship, parent: e1, child: e2) }

      it "returns relationships where an enterprise is the parent" do
        EnterpriseRelationship.involving_enterprises([e1]).should == [er]
      end

      it "returns relationships where an enterprise is the child" do
        EnterpriseRelationship.involving_enterprises([e2]).should == [er]
      end

      it "does not return other relationships" do
        EnterpriseRelationship.involving_enterprises([e3]).should == []
      end
    end

    describe "creating with a permission list" do
      it "creates permissions with a list" do
        er = EnterpriseRelationship.create! parent: e1, child: e2, permissions_list: ['one', 'two']
        er.reload
        er.permissions.map(&:name).sort.should == ['one', 'two'].sort
      end

      it "does nothing when the list is nil" do
        er = EnterpriseRelationship.create! parent: e1, child: e2, permissions_list: nil
        er.reload
        er.permissions.should be_empty
      end
    end

    it "finds relationships that grant permissions to some enterprises" do
      er1 = create(:enterprise_relationship, parent: e2, child: e1)
      er2 = create(:enterprise_relationship, parent: e3, child: e2)
      er3 = create(:enterprise_relationship, parent: e1, child: e3)

      EnterpriseRelationship.permitting([e1, e2]).sort.should == [er1, er2]
    end

    it "finds relationships that grant a particular permission" do
      er1 = create(:enterprise_relationship, parent: e1, child: e2,
                   permissions_list: ['one', 'two'])
      er2 = create(:enterprise_relationship, parent: e2, child: e3,
                   permissions_list: ['two', 'three'])
      er3 = create(:enterprise_relationship, parent: e3, child: e1,
                   permissions_list: ['three', 'four'])

      EnterpriseRelationship.with_permission('two').sort.should == [er1, er2].sort
    end
  end
end
