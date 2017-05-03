Spree::MailMethod.class_eval do
  preference :send_from_enterprise_address, :boolean, default: false

  attr_accessible :preferred_send_from_enterprise_address
end
