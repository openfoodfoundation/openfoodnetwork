require 'spec_helper'

module OpenFoodNetwork
  describe OrderAndDistributorReport do
    include AuthenticationWorkflow

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

      it "sorts unconfirmed enterprises to the top" do
        uae_mock = [
          { "confirmed_at" => "2015-01-01", "name" => "aaa" },
          { "confirmed_at" => nil, "name" => "bbb" }
        ]
        expect(subject.sort uae_mock).to eq [ uae_mock[1], uae_mock[0] ]
      end

      it "then sorts by confirmation date" do
        uae_mock = [
          { "confirmed_at" => "2015-01-01", "name" => "bbb" },
          { "confirmed_at" => "2015-01-02", "name" => "aaa" }
        ]
        expect(subject.sort uae_mock).to eq [ uae_mock[1], uae_mock[0] ]
      end

      it "then sorts by name" do
        uae_mock = [
          { "name" => "aaa", "relationship_type" => "bbb", "user_email" => "bbb" },
          { "name" => "bbb", "relationship_type" => "aaa", "user_email" => "aaa" }
        ]
        expect(subject.sort uae_mock).to eq [ uae_mock[0], uae_mock[1] ]
      end

      it "then sorts by relationship type (reveresed)" do
        uae_mock = [
          { "name" => "aaa", "relationship_type" => "bbb", "user_email" => "bbb" },
          { "name" => "aaa", "relationship_type" => "aaa", "user_email" => "aaa" },
          { "name" => "aaa", "relationship_type" => "bbb", "user_email" => "aaa" }
        ]
        expect(subject.sort uae_mock).to eq [ uae_mock[2], uae_mock[0], uae_mock[1] ]
      end

      it "then sorts by user_email" do
        uae_mock = [
          { "name" => "aaa", "relationship_type" => "bbb", "user_email" => "aaa" },
          { "name" => "aaa", "relationship_type" => "aaa", "user_email" => "aaa" },
          { "name" => "aaa", "relationship_type" => "aaa", "user_email" => "bbb" }
        ]
        expect(subject.sort uae_mock).to eq [ uae_mock[0], uae_mock[1], uae_mock[2] ]
      end
    end

    describe "filtering results" do
      let!(:enterprise1) { create(:enterprise, owner: create_enterprise_user ) }
      let!(:enterprise2) { create(:enterprise, owner: create_enterprise_user ) }

      describe "for owners and enterprises" do
        describe "by enterprise id" do
          let!(:params) { { enterprise_id_in: [enterprise1.id.to_s] } }
          let!(:subject) { OpenFoodNetwork::UsersAndEnterprisesReport.new params }

          it "excludes enterprises that are not explicitly requested" do
            results = subject.owners_and_enterprises.to_a.map{ |oae| oae["name"] }
            expect(results).to include enterprise1.name
            expect(results).to_not include enterprise2.name
          end
        end

        describe "by user id" do
          let!(:params) { { user_id_in: [enterprise1.owner.id.to_s] } }
          let!(:subject) { OpenFoodNetwork::UsersAndEnterprisesReport.new params }

          it "excludes enterprises that are not explicitly requested" do
            results = subject.owners_and_enterprises.to_a.map{ |oae| oae["name"] }
            expect(results).to include enterprise1.name
            expect(results).to_not include enterprise2.name
          end
        end
      end

      describe "for managers and enterprises" do
        describe "by enterprise id" do
          let!(:params) { { enterprise_id_in: [enterprise1.id.to_s] } }
          let!(:subject) { OpenFoodNetwork::UsersAndEnterprisesReport.new params }

          it "excludes enterprises that are not explicitly requested" do
            results = subject.managers_and_enterprises.to_a.map{ |mae| mae["name"] }
            expect(results).to include enterprise1.name
            expect(results).to_not include enterprise2.name
          end
        end

        describe "by user id" do
          let!(:manager1) { create_enterprise_user }
          let!(:manager2) { create_enterprise_user }
          let!(:params) { { user_id_in: [manager1.id.to_s] } }
          let!(:subject) { OpenFoodNetwork::UsersAndEnterprisesReport.new params }

          before do
            enterprise1.enterprise_roles.build(user: manager1).save
            enterprise2.enterprise_roles.build(user: manager2).save
          end

          it "excludes enterprises whose managers are not explicitly requested" do
            results = subject.managers_and_enterprises.to_a.map{ |mae| mae["name"] }
            expect(results).to include enterprise1.name
            expect(results).to_not include enterprise2.name
          end
        end
      end
    end
  end
end
