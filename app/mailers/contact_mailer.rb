class ContactMailer < ApplicationMailer
  def contact_email(name, email, message, subject)
    @name = name
    @message = message

    mail(to: 'contact.afg.updates@gmail.com', subject: subject, from: email) do |format|
      format.text { render plain: message }
    end
  end
end
