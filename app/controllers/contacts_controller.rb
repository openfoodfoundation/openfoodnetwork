class ContactsController < ApplicationController
    def create
      # Process the form data
      name = params[:name]
      email = params[:email]
      subject = params[:subject]
      message = params[:message]
  
      # Send email
      ContactMailer.contact_email(name, email, message, subject).deliver_now
  
      # Redirect back to the form or to a thank you page
      redirect_to root_path, notice: 'Your message has been sent. Thank you!'
    end
  end
  