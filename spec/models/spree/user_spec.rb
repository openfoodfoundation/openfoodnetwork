describe Spree.user_class do
  context "#create" do

    it "should send a signup email" do
      Spree::UserMailer.should_receive(:signup_confirmation).and_return(double(:deliver => true))
      create(:user)
    end
  end
end
