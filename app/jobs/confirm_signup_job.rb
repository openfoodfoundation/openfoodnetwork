ConfirmSignupJob = Struct.new(:user_id) do
  def perform
    user = Spree::User.find user_id
    Spree::UserMailer.signup_confirmation(user).deliver
  end
end
