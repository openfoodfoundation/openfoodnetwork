describe Spree.user_class do
  describe "associations" do
    it { should have_many(:owned_enterprises) }

    describe "enterprise ownership" do
      let(:u) { create(:user) }
      let(:e1) { create(:enterprise, owner: u) }
      let(:e2) { create(:enterprise, owner: u) }
      it "provides access to owned enteprises" do
        expect(u.owned_enterprises).to include e1, e2
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
