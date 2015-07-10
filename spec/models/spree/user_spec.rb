describe Spree.user_class do
  include AuthenticationWorkflow

  describe "associations" do
    it { should have_many(:owned_enterprises) }

    describe "enterprise ownership" do
      let(:u1) { create(:user, enterprise_limit: 2) }
      let(:u2) { create(:user, enterprise_limit: 1) }
      let!(:e1) { create(:enterprise, owner: u1) }
      let!(:e2) { create(:enterprise, owner: u1) }

      it "provides access to owned enterprises" do
        expect(u1.owned_enterprises(:reload)).to include e1, e2
      end

      it "enforces the limit on the number of enterprise owned" do
        expect(u2.owned_enterprises(:reload)).to eq []
        u2.owned_enterprises << e1
        expect(u2.save!).to_not raise_error
        expect {
          u2.owned_enterprises << e2
          u2.save!
        }.to raise_error ActiveRecord::RecordInvalid, "Validation failed: #{u2.email} is not permitted to own any more enterprises (limit is 1)."
      end
    end

    describe "group ownership" do
      let(:u1) { create(:user) }
      let(:u2) { create(:user) }
      let!(:g1) { create(:enterprise_group, owner: u1) }
      let!(:g2) { create(:enterprise_group, owner: u1) }
      let!(:g3) { create(:enterprise_group, owner: u2) }

      it "provides access to owned groups" do
        expect(u1.owned_groups(:reload)).to match_array([g1, g2])
        expect(u2.owned_groups(:reload)).to match_array([g3])
      end
    end

    it "loads a user's customer representation at a particular enterprise" do
      u = create(:user)
      e = create(:enterprise)
      c = create(:customer, user: u, enterprise: e)

      u.customer_of(e).should == c
    end
  end

  context "#create" do
    it "should send a signup email" do
      expect do
        create(:user)
      end.to enqueue_job ConfirmSignupJob
    end
  end

  describe "known_users" do
    let!(:u1) { create(:user) }
    let!(:u2) { create(:user) }
    let!(:u3) { create(:user) }
    let!(:e1) { create(:enterprise, owner: u1, users: [u1, u2]) }

    describe "as an enterprise user" do
      it "returns a list of users which manage shared enterprises" do
        expect(u1.known_users).to include u1, u2
        expect(u1.known_users).to_not include u3
        expect(u2.known_users).to include u1,u2
        expect(u2.known_users).to_not include u3
        expect(u3.known_users).to_not include u1,u2,u3
      end
    end

    describe "as admin" do
      let(:admin) { quick_login_as_admin }

      it "returns all users" do
        expect(admin.known_users).to include u1, u2, u3
      end
    end
  end

  describe "invoice_for" do
    let!(:user) { create(:user) }
    let!(:accounts_distributor) { create(:distributor_enterprise) }
    let!(:start_of_month) { Time.now.beginning_of_month }

    before do
      Spree::Config.accounts_distributor_id = accounts_distributor.id
    end

    context "where no relevant invoice exists for the given period" do
      # Created during previous month
      let!(:order1) { create(:order, user: user, created_at: start_of_month - 3.hours, completed_at: nil, distributor: accounts_distributor) }
      # Incorrect distributor
      let!(:order3) { create(:order, user: user, created_at: start_of_month + 3.hours, completed_at: nil, distributor: create(:distributor_enterprise)) }
      # Incorrect user
      let!(:order4) { create(:order, user: create(:user), created_at: start_of_month + 3.hours, completed_at: nil, distributor: accounts_distributor) }

      it "creates a new invoice" do
        current_invoice = user.invoice_for(start_of_month, start_of_month + 20.days)
        expect(current_invoice).to be_a_new Spree::Order
        expect(current_invoice.completed_at).to be nil
        expect(current_invoice.distributor).to eq accounts_distributor
        expect(current_invoice.user).to eq user
      end
    end

    context "where an invoice exists for the current month" do
      let!(:order) { create(:order, user: user, created_at: start_of_month + 3.hours, completed_at: nil, distributor: accounts_distributor) }

      it "returns the existing invoice" do
        current_invoice = user.invoice_for(start_of_month, start_of_month + 20.days)
        expect(current_invoice).to eq order
      end
    end
  end
end
