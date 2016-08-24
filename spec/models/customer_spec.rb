require 'spec_helper'

describe Customer, type: :model do
  describe 'an existing customer' do
    let(:customer) { create(:customer) }

    it "saves its code" do
      code = "code one"
      customer.code = code
      customer.save
      expect(customer.code).to eq code
    end

    it "can remove its code" do
      customer.code = ""
      customer.save
      expect(customer.code).to be nil
    end
  end

  describe 'update shipping address' do
    let(:customer) { create(:customer) }

    it 'updates the shipping address' do
      expect(customer.shipping_address).to be_nil

      ship_address = {firstname: 'fname',
                      lastname: 'lname',
                      zipcode: "3127",
                      city: "Melbourne",
                      state_id: 1,
                      phone: "455500146",
                      address1: "U 3/32 Florence Road Surrey Hills2",
                      country_id: 1}
      customer.update_attributes!(ship_address_attributes: ship_address)

      expect(customer.ship_address.city).to eq 'Melbourne'
      expect(customer.ship_address.firstname).to eq 'fname'
      expect(customer.ship_address.lastname).to eq 'lname'
    end
  end

  describe 'creation callbacks' do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:enterprise) { create(:distributor_enterprise) }

    it "associates no user using non-existing email" do
      c = Customer.create(enterprise: enterprise, email: 'some-email-not-associated-with-a-user@email.com')
      expect(c.user).to be_nil
    end

    it "associates an existing user using email" do
      non_existing_email = 'some-email-not-associated-with-a-user@email.com'
      c1 = Customer.create(enterprise: enterprise, email: non_existing_email, user: user1)
      expect(c1.user).to eq user1
      expect(c1.email).to eq non_existing_email
      expect(c1.email).to_not eq user1.email

      c2 = Customer.create(enterprise: enterprise, email: user2.email)
      expect(c2.user).to eq user2
    end

    it "associates an existing user using email case-insensitive" do
      c = Customer.create(enterprise: enterprise, email: user2.email.upcase)
      expect(c.user).to eq user2
    end
  end
end
