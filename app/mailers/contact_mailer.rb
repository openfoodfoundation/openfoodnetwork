class ContactMailer < ApplicationMailer
    def contact_email(name, email, message, subject)
      @name = name
      @message = message
  
      mail(from: email, to: 'fruits@labelleorange.es', subject: subject)
    end
  end
  