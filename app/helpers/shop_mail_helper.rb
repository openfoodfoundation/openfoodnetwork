# frozen_string_literal: true

module ShopMailHelper
  # Long datetime format string used in emails to customers
  #
  # Example: "Fri Aug 31 @ 11:00PM"
  def mail_long_datetime_format
    "%a %b %d @ %l:%M%p"
  end
end
