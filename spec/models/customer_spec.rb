# frozen_string_literal: false

RSpec.describe Customer do
  it { is_expected.to belong_to(:enterprise).required }
  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to belong_to(:bill_address).optional }
  it { is_expected.to belong_to(:ship_address).optional }
  it { is_expected.to have_many(:customer_account_transactions) }
  it {
    is_expected.to define_enum_for(:customer_type)
      .with_values(individual: "individual", enterprise: "enterprise")
      .with_default("individual")
      .backed_by_column_of_type(:enum)
  }

  context "for an enterprise customer" do
    before { allow(subject).to receive(:enterprise?).and_return(true) }

    it { is_expected.to validate_presence_of(:enterprise_name) }
    it { is_expected.to validate_presence_of(:enterprise_abn) }
  end

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
      c = Customer.create(enterprise:,
                          email: 'some-email-not-associated-with-a-user@email.com')
      expect(c.user).to be_nil
    end

    it "associates an existing user using email" do
      non_existing_email = 'some-email-not-associated-with-a-user@email.com'
      c1 = Customer.create(enterprise:, email: non_existing_email, user: user1)
      expect(c1.user).to eq user1
      expect(c1.email).to eq non_existing_email
      expect(c1.email).not_to eq user1.email

      c2 = Customer.create(enterprise:, email: user2.email)
      expect(c2.user).to eq user2
    end

    it "associates an existing user using email case-insensitive" do
      c = Customer.create(enterprise:, email: user2.email.upcase)
      expect(c.user).to eq user2
    end
  end

  describe 'scopes' do
    context 'managed_by' do
      let!(:user) { create(:user) }
      let!(:enterprise) { create(:enterprise, owner: user) }
      let!(:customer) { create(:customer, enterprise:, user:) }
      let!(:customer1) { create(:customer, enterprise:) }

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
        EnterpriseRole.create!(user: user2, enterprise:)
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

      let!(:order_ready_for_details) { create(:order_ready_for_details, customer:) }
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

  describe "#full_name" do
    context "when customer type is individual" do
      let(:customer) {
        build(:customer, customer_type: "individual", first_name: "Jane", last_name: "Doe")
      }

      it "returns first and last name joined" do
        expect(customer.full_name).to eq("Jane Doe")
      end

      context "when only first name is present" do
        let(:customer) {
          build(:customer, customer_type: "individual", first_name: "Jane", last_name: nil)
        }

        it "returns first name without trailing space" do
          expect(customer.full_name).to eq("Jane")
        end
      end

      context "when both names are blank" do
        let(:customer) {
          build(:customer, customer_type: "individual", first_name: nil, last_name: nil)
        }

        it "returns an empty string" do
          expect(customer.full_name).to eq("")
        end
      end
    end

    context "when customer type is enterprise" do
      let(:customer) {
        build(:customer, customer_type: "enterprise", enterprise_name: "Acme Corp",
                         enterprise_acn: "123456789", enterprise_abn: "11223344556")
      }

      it "returns the enterprise name" do
        expect(customer.full_name).to eq("Acme Corp")
      end
    end
  end

  describe "#credit_balance" do
    subject(:customer) { create(:customer) }

    it "returns the availble credit balance" do
      create(:customer_account_transaction, customer:, amount: 5)
      create(:customer_account_transaction, customer:, amount: 10)

      expect(customer.credit_balance).to eq(15.00)
    end

    context "when no existing customer account transaction" do
      it "returns 0" do
        expect(customer.credit_balance).to eq(0.00)
      end
    end
  end

  describe "#destroy" do
    let(:customer) { create(:customer) }

    context "when customer has no credit transactions" do
      it "destroys the customer" do
        expect(customer.destroy).to be_truthy
      end
    end

    context "when customer has credit transactions" do
      it "destroys the customer and cleans up transactions if balance is zero" do
        create(:customer_account_transaction, customer:, amount: 10.00)
        create(:customer_account_transaction, customer:, amount: -10.00)
        expect { customer.destroy }.to change { CustomerAccountTransaction.count }.by(-2)
        expect(customer).to be_destroyed
      end

      it "does not destroy the customer if there is outstanding credit" do
        create(:customer_account_transaction, customer:, amount: 10.00)
        expect(customer.destroy).to be false
        expect(customer.errors[:base]).to include(
          I18n.t("admin.customers.destroy.has_outstanding_credit")
        )
      end
    end

    context "when customer has subscriptions" do
      it "destroys the customer and cleans up canceled subscriptions" do
        create(:subscription, customer:, canceled_at: Time.zone.now)
        expect { customer.destroy }.to change { Subscription.count }.by(-1)
        expect(customer).to be_destroyed
      end

      it "does not destroy the customer if there are active subscriptions" do
        create(:subscription, customer:)
        expect(customer.destroy).to be false
        expect(customer.errors[:base]).to include(
          I18n.t("admin.customers.destroy.has_associated_subscriptions")
        )
      end

      it "returns false when associated subscription destroy fails" do
        create(:subscription, customer:, canceled_at: Time.zone.now)

        allow_any_instance_of(Subscription).to receive(:destroy).and_return(false)

        expect(customer.destroy).to be false
      end
    end
  end
end
