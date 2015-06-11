require 'spec_helper'

describe Customer, type: :model do
  describe 'creation callbacks' do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:enterprise) { create(:distributor_enterprise) }

    it "associates an existing user using email" do
      c1 = Customer.create(enterprise: enterprise, email: 'some-email-not-associated-with-a-user@email.com')
      expect(c1.user).to be_nil

      c2 = Customer.create(enterprise: enterprise, email: 'some-email-not-associated-with-a-user@email.com', user: user1)
      expect(c2.user).to eq user1

      c3 = Customer.create(enterprise: enterprise, email: user2.email)
      expect(c3.user).to eq user2
    end
  end
end
