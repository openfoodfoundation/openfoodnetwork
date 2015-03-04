require 'spec_helper'

describe Spree::Admin::SearchController do
  include AuthenticationWorkflow
  context "Distributor Enterprise User" do
    let!(:owner) { create_enterprise_user( email: "test1@email.com" ) }
    let!(:manager) { create_enterprise_user( email: "test2@email.com" ) }
    let!(:random) { create_enterprise_user( email: "test3@email.com" ) }
    let!(:enterprise) { create(:enterprise, owner: owner, users: [owner, manager]) }
    before { login_as_enterprise_user [enterprise] }

    describe 'searching for known users' do
      describe "when search query is not an exact match" do
        before do
          spree_get :known_users, q: "test"
        end

        it "returns a list of users that I share management of enteprises with" do
          expect(assigns(:users)).to include owner, manager
          expect(assigns(:users)).to_not include random
        end
      end

      describe "when search query exactly matches the email of a user in the system" do
        before do
          spree_get :known_users, q: "test3@email.com"
        end

        it "returns that user, regardless of the relationship between the two users" do
          expect(assigns(:users)).to eq [random]
        end
      end
    end
  end
end
