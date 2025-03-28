# frozen_string_literal: true

module MailersHelper
  def html_body(mail)
    Capybara.string(mail.html_part.body.to_s)
  end
end
