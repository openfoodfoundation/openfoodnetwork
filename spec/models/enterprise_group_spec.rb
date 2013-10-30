require 'spec_helper'

describe EnterpriseGroup do
  describe "validations" do
    it "is valid when built from factory" do
      e = build(:enterprise_group)
      e.should be_valid
    end

    it "requires a name" do
      e = build(:enterprise_group, name: '')
      e.should_not be_valid
    end
  end

  describe "relations" do
    it "habtm enterprises" do
      e = create(:supplier_enterprise)
      eg = create(:enterprise_group)
      eg.enterprises << e
      eg.reload.enterprises.should == [e]
    end

    # it "can have an image" do
    #   eg = create(:enterprise_group)
    #   image_file = File.open(File.expand_path('../../../app/assets/images/logo.jpg', __FILE__))
    #   image = Spree::Image.create(viewable_id: eg.id, viewable_type: 'EnterpriseGroup', attachment: image_file)
    #   eg.reload.image.should == image
    # end
  end

  describe "scopes" do
    it "orders enterprise groups by their position" do
      eg1 = create(:enterprise_group, position: 1)
      eg2 = create(:enterprise_group, position: 3)
      eg3 = create(:enterprise_group, position: 2)

      EnterpriseGroup.by_position.should == [eg1, eg3, eg2]
    end

    it "finds enterprise groups on the front page" do
      eg1 = create(:enterprise_group, on_front_page: true)
      eg2 = create(:enterprise_group, on_front_page: false)

      EnterpriseGroup.on_front_page.should == [eg1]
    end
  end
end
