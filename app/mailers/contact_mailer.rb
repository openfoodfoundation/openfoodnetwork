class ContactMailer < ApplicationMailer
  def contact_email(name, email, message, subject)
    @name = name
    @message = message

    mail(
      to: 'fruits@labelleorange.es',
      from: email,  
      subject: subject
    )    
  end
end
  