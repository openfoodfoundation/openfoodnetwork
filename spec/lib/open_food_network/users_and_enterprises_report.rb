require 'spec_helper'


module OpenFoodNetwork
  describe OrderAndDistributorReport do

    describe "users_and_enterprises" do
      let!(:owners_and_enterprises) { double(:owners_and_enterprises) }
      let!(:managers_and_enterprises) { double(:managers_and_enterprises) }
      let!(:subject) { OpenFoodNetwork::UsersAndEnterprisesReport.new {} }

      before do
        subject.stub(:owners_and_enterprises) { owners_and_enterprises }
        subject.stub(:managers_and_enterprises) { managers_and_enterprises }
      end

      it "should concatenate owner and manager queries" do
        expect(subject).to receive(:owners_and_enterprises).once
        expect(subject).to receive(:managers_and_enterprises).once
        expect(owners_and_enterprises).to receive(:concat).with(managers_and_enterprises).and_return []
        expect(subject).to receive(:sort).with []
        subject.users_and_enterprises
      end
    end

    describe "sorting results" do
      let!(:subject) { OpenFoodNetwork::UsersAndEnterprisesReport.new {} }

      it "sorts by name first" do
        uae_mock = [
          { "name" => "aaa", "relationship_type" => "bbb", "user_email" => "bbb" },
          { "name" => "bbb", "relationship_type" => "aaa", "user_email" => "aaa" }
        ]
        expect(subject.sort uae_mock).to eq [ uae_mock[0], uae_mock[1] ]
      end

      it "sorts by relationship type (reveresed) second" do
        uae_mock = [
          { "name" => "aaa", "relationship_type" => "bbb", "user_email" => "bbb" },
          { "name" => "aaa", "relationship_type" => "aaa", "user_email" => "aaa" },
          { "name" => "aaa", "relationship_type" => "bbb", "user_email" => "aaa" }
        ]
        expect(subject.sort uae_mock).to eq [ uae_mock[2], uae_mock[0], uae_mock[1] ]
      end

      it "sorts by user_email third" do
        uae_mock = [
          { "name" => "aaa", "relationship_type" => "bbb", "user_email" => "aaa" },
          { "name" => "aaa", "relationship_type" => "aaa", "user_email" => "aaa" },
          { "name" => "aaa", "relationship_type" => "aaa", "user_email" => "bbb" }
        ]
        expect(subject.sort uae_mock).to eq [ uae_mock[0], uae_mock[1], uae_mock[2] ]
      end
    end
  end
end