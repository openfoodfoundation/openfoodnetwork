describe Spree.user_class do
  describe "associations" do
    it { should have_many(:owned_enterprises) }

    describe "enterprise ownership" do
      let(:u1) { create(:user) }
      let(:u2) { create(:user) }
      let(:e1) { create(:enterprise, owner: u1) }
      let(:e2) { create(:enterprise, owner: u1) }

      it "provides access to owned enteprises" do
        expect(u1.owned_enterprises).to include e1, e2
      end

      it "enforces the limit on the number of enterprise owned" do
        expect(u2.owned_enterprises).to eq []
        u2.owned_enterprises << e1
        u2.owned_enterprises << e2
        expect {
          u2.save!
        }.to raise_error ActiveRecord::RecordInvalid, "Validation failed: The nominated user is not permitted to own own any more enterprises."

      end
    end
  end

  context "#create" do
    it "should send a signup email" do
      Spree::UserMailer.should_receive(:signup_confirmation).and_return(double(:deliver => true))
      create(:user)
    end
  end
end
