class ContactMailer < ApplicationMailer
  def contact_email(name, email, message, subject)
    @name = name
    @message = message
    @user_email = email 

    mail(to: ContentConfig.footer_email, subject: subject) do |format|
      format.text { render plain: "User Email: #{@user_email}\n\n#{@message}" }
    end
  end
end
