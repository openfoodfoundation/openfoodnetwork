module CanCanUnauthorizedMessage
  # Fix deprecated syntax calling I18n#translate (using keyword args) without using **
  def unauthorized_message(action, subject)
    keys = unauthorized_message_keys(action, subject)
    variables = {:action => action.to_s}
    variables[:subject] = (subject.class == Class ? subject : subject.class).to_s.underscore.humanize.downcase
    message = I18n.translate(nil, **variables.merge(:scope => :unauthorized, :default => keys + [""]))
    message.blank? ? nil : message
  end
end

CanCan::Ability.prepend(CanCanUnauthorizedMessage)
