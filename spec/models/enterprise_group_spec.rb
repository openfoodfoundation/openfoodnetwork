# frozen_string_literal: false

require 'spec_helper'

describe EnterpriseGroup do
  describe "associations" do
    subject { build(:enterprise_group) }

    it { is_expected.to belong_to(:owner).optional }
    it { is_expected.to belong_to(:address).required }
  end

  describe "validations" do
    it "pass with name, description and address" do
      e = EnterpriseGroup.new
      e.name = 'Test Group'
      e.description = 'A valid test group.'
      e.address = build(:address)
      expect(e).to be_valid
    end

    it "is valid when built from factory" do
      e = build(:enterprise_group)
      expect(e).to be_valid
    end

    it "replace empty permalink and pass" do
      e = build(:enterprise_group, permalink: '')
      expect(e).to be_valid
      expect(e.permalink).to eq(e.name.parameterize)
    end

    it "restores permalink and pass" do
      e = create(:enterprise_group, permalink: 'p')
      e.permalink = ''
      expect(e).to be_valid
      expect(e.permalink).to eq('p')
    end

    it "requires a name" do
      e = build(:enterprise_group, name: '')
      expect(e).not_to be_valid
    end

    it "requires a description" do
      e = build(:enterprise_group, description: '')
    end

    it { is_expected.to have_one_attached :promo_image }
    it { is_expected.to have_one_attached :logo }
  end

  describe "relations" do
    it "habtm enterprises" do
      e = create(:supplier_enterprise)
      eg = create(:enterprise_group)
      eg.enterprises << e
      expect(eg.reload.enterprises).to eq([e])
    end
  end

  describe "scopes" do
    it "orders enterprise groups by their position" do
      eg1 = create(:enterprise_group, position: 1)
      eg2 = create(:enterprise_group, position: 3)
      eg3 = create(:enterprise_group, position: 2)

      expect(EnterpriseGroup.by_position.to_a).to eq([eg1, eg3, eg2])
    end

    it "finds enterprise groups on the front page" do
      eg1 = create(:enterprise_group, on_front_page: true)
      eg2 = create(:enterprise_group, on_front_page: false)

      expect(EnterpriseGroup.on_front_page).to eq([eg1])
    end

    it "finds a user's enterprise groups" do
      user = create(:user)
      user.spree_roles = []
      eg1 = create(:enterprise_group, owner: user)
      eg2 = create(:enterprise_group)

      expect(EnterpriseGroup.managed_by(user)).to eq([eg1])
    end

    describe "finding a permalink" do
      it "finds available permalink" do
        existing = []
        expect(EnterpriseGroup.find_available_value(existing, "permalink")).to eq "permalink"
      end

      it "finds available permalink similar to existing" do
        existing = ["permalink1"]
        expect(EnterpriseGroup.find_available_value(existing, "permalink")).to eq "permalink"
      end

      it "adds unique number to existing permalinks" do
        existing = ["permalink"]
        expect(EnterpriseGroup.find_available_value(existing, "permalink")).to eq "permalink1"
        existing = ["permalink", "permalink1"]
        expect(EnterpriseGroup.find_available_value(existing, "permalink")).to eq "permalink2"
      end

      it "ignores permalinks with characters after the index value" do
        existing = ["permalink", "permalink1", "permalink2xxx"]
        expect(EnterpriseGroup.find_available_value(existing, "permalink")).to eq "permalink2"
      end

      it "finds gaps in the indices of existing permalinks" do
        existing = ["permalink", "permalink1", "permalink3"]
        expect(EnterpriseGroup.find_available_value(existing, "permalink")).to eq "permalink2"
      end

      it "finds available indexed permalink" do
        existing = ["permalink", "permalink1"]
        expect(EnterpriseGroup.find_available_value(existing, "permalink1")).to eq "permalink11"
      end
    end
  end
end
