Spree::UserMailer.class_eval do
  def signup_confirmation(user)
    @user = user
    mail(:to => user.email, :from => from_address,
         :subject => t(:welcome_to) + Spree::Config[:site_name])
  end

  def confirmation_instructions(user, token)
    @user = user
    @token = token
    subject = t('spree.user_mailer.confirmation_instructions.subject')
    mail(to: user.email,
         from: from_address,
         subject: subject)
  end
end
