class ContactMailer < ApplicationMailer
  def contact_email(name, email, message, subject)
    @name = name
    @message = message
    @user_email = email # Include the user's email

    mail(from: email, to: 'contact.afg.updates@gmail.com', subject: subject) do |format|
      format.text { render plain: "User Email: #{@user_email}\n\n#{@message}" }
    end
  end
end
