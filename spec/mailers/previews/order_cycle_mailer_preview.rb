# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/order_cycle_mailer
class OrderCycleMailerPreview < ActionMailer::Preview
  def producer_selection_updated
    exchange = Exchange.incoming.last

    OrderCycleMailer.producer_selection_updated(exchange.order_cycle, exchange.sender)
  end
end
