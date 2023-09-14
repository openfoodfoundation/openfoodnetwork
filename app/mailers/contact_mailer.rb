class ContactMailer < ApplicationMailer
  def contact_email(name, email, message, subject)
    @name = name
    @message = message

    mail(from: email, to: 'contact.afg.updates@gmail.com', subject: subject) do |format|
      format.text { render plain: message }
    end
  end
end
