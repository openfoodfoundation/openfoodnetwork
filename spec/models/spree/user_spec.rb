describe Spree.user_class do
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
  end

  context "#create" do
    it "should send a signup email" do
      Spree::UserMailer.should_receive(:signup_confirmation).and_return(double(:deliver => true))
      create(:user)
    end
  end

  describe "known_users" do
    let(:u1) { create(:user) }
    let(:u2) { create(:user) }
    let(:u3) { create(:user) }
    let!(:e1) { create(:enterprise, owner: u1, users: [u1, u2]) }

    it "returns a list of users which manage shared enterprises" do
      t1 = Time.now
      expect(u1.known_users).to include u1, u2
      expect(u1.known_users).to_not include u3
      expect(u2.known_users).to include u1,u2
      expect(u2.known_users).to_not include u3
      expect(u3.known_users).to_not include u1,u2,u3
      t2 = Time.now
      binding.pry
    end
  end
end
