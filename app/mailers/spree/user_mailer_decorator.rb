Spree::UserMailer.class_eval do
  
  def signup_confirmation(user)
    @user = user
    mail(:to => user.email, :from => from_address,
         :subject => 'Welcome to ' + Spree::Config[:site_name])
  end
end
