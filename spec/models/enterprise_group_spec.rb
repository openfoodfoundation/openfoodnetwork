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
end
