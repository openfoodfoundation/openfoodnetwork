# frozen_string_literal: false

require 'spec_helper'

describe Customer, type: :model do
  it { is_expected.to belong_to(:enterprise).required }
  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to belong_to(:bill_address).optional }
  it { is_expected.to belong_to(:ship_address).optional }

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

      ship_address = { firstname: 'fname',
                       lastname: 'lname',
                       zipcode: "3127",
                       city: "Melbourne",
                       state_id: 1,
                       phone: "455500146",
                       address1: "U 3/32 Florence Road Surrey Hills2",
                       country_id: 1 }
      customer.update!(ship_address_attributes: ship_address)

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
      c = Customer.create(enterprise: enterprise,
                          email: 'some-email-not-associated-with-a-user@email.com')
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

  describe 'scopes' do
    context 'managed_by' do
      let!(:user) { create(:user) }
      let!(:enterprise) { create(:enterprise, owner: user) }
      let!(:customer) { create(:customer, enterprise: enterprise, user: user) }
      let!(:customer1) { create(:customer, enterprise: enterprise) }

      let!(:user1) { create(:user) }
      let!(:enterprise1) { create(:enterprise, owner: user1) }
      let!(:customer2) { create(:customer, enterprise: enterprise1, user: user1) }

      let(:guest) { Spree::User.new }

      context 'with user who has edit profile permission on enterprise via enterprise2' do
        let!(:user3) { create(:user) }
        let!(:enterprise2) { create(:enterprise, owner: user3) }

        it 'returns customers managed by the user' do
          EnterpriseRelationship.create!(parent: enterprise2, child: enterprise,
                                         permissions_list: [:edit_profile])
          expect(Customer.managed_by(user)).to match_array [customer, customer1]
          expect(Customer.managed_by(user1)).to match_array(customer2)
          expect(Customer.managed_by(user3)).to match_array([])
        end
      end

      it 'returns customers of managed enterprises' do
        user2 = create(:user)
        EnterpriseRole.create!(user: user2, enterprise: enterprise)
        expect(Customer.managed_by(user2)).to match_array [customer, customer1]
      end

      it 'returns all customers if the user is an admin' do
        admin = create(:admin_user)
        expect(Customer.managed_by(admin)).to match_array [customer, customer1, customer2]
      end

      it 'returns no customers if the user is non-persisted user object' do
        expect(Customer.managed_by(guest)).to match_array []
      end
    end

    context 'visible' do
      let!(:customer) { create(:customer) }
      let!(:customer2) { create(:customer) }
      let!(:customer3) { create(:customer) }
      let!(:customer4) { create(:customer) }
      let!(:customer5) { create(:customer, created_manually: true) }

      let!(:order_ready_for_details) { create(:order_ready_for_details, customer: customer) }
      let!(:order_ready_for_payment) { create(:order_ready_for_payment, customer: customer2) }
      let!(:order_ready_for_confirmation) {
        create(:order_ready_for_confirmation, customer: customer3)
      }
      let!(:completed_order) { create(:completed_order_with_totals, customer: customer4) }

      it 'returns customers with completed orders' do
        expect(Customer.visible).to match_array [customer4, customer5]
      end
    end
  end
end
