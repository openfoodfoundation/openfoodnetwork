module OpenFoodNetwork
  class PaymentsReport
    attr_reader :params
    def initialize(user, params = {})
      @params = params
      @user = user
    end

    def header
      case params[:report_type]
      when "payments_by_payment_type"
        ["Payment State", "Distributor", "Payment Type", "Total (#{currency_symbol})"]
      when "itemised_payment_totals"
        ["Payment State", "Distributor", "Product Total (#{currency_symbol})", "Shipping Total (#{currency_symbol})", "Outstanding Balance (#{currency_symbol})", "Total (#{currency_symbol})"]
      when "payment_totals"
        ["Payment State", "Distributor", "Product Total (#{currency_symbol})", "Shipping Total (#{currency_symbol})", "Total (#{currency_symbol})", "EFT (#{currency_symbol})", "PayPal (#{currency_symbol})", "Outstanding Balance (#{currency_symbol})"]
      else
        ["Payment State", "Distributor", "Payment Type", "Total (#{currency_symbol})"]
      end
    end

    def search
      Spree::Order.complete.not_state(:canceled).managed_by(@user).search(params[:q])
    end

    def table_items
      orders = search.result
      payments = orders.map { |o| o.payments.select { |payment| payment.completed? } }.flatten # Only select completed payments
      case params[:report_type]
      when "payments_by_payment_type"
        payments
      when "itemised_payment_totals"
        orders
      when "payment_totals"
        orders
      else
        payments
      end
    end

    def rules
      case params[:report_type]
      when "payments_by_payment_type"
        [ { group_by: proc { |payment| payment.order.payment_state },
          sort_by: proc { |payment_state| payment_state } },
          { group_by: proc { |payment| payment.order.distributor },
          sort_by: proc { |distributor| distributor.name } },
          { group_by: proc { |payment| Spree::PaymentMethod.unscoped { payment.payment_method } },
          sort_by: proc { |method| method.name } } ]
      when "itemised_payment_totals"
        [ { group_by: proc { |order| order.payment_state },
          sort_by: proc { |payment_state| payment_state } },
          { group_by: proc { |order| order.distributor },
          sort_by: proc { |distributor| distributor.name } } ]
      when "payment_totals"
        [ { group_by: proc { |order| order.payment_state },
          sort_by: proc { |payment_state| payment_state } },
          { group_by: proc { |order| order.distributor },
          sort_by: proc { |distributor| distributor.name } } ]
      else
        [ { group_by: proc { |payment| payment.order.payment_state },
          sort_by: proc { |payment_state| payment_state } },
          { group_by: proc { |payment| payment.order.distributor },
          sort_by: proc { |distributor| distributor.name } },
          { group_by: proc { |payment| payment.payment_method },
          sort_by: proc { |method| method.name } } ]
      end
    end

    def columns
      case params[:report_type]
      when "payments_by_payment_type"
        [ proc { |payments| payments.first.order.payment_state },
          proc { |payments| payments.first.order.distributor.name },
          proc { |payments| payments.first.payment_method.name },
          proc { |payments| payments.sum { |payment| payment.amount } } ]
      when "itemised_payment_totals"
        [ proc { |orders| orders.first.payment_state },
          proc { |orders| orders.first.distributor.name },
          proc { |orders| orders.sum { |o| o.item_total } },
          proc { |orders| orders.sum { |o| o.ship_total } },
          proc { |orders| orders.sum { |o| o.outstanding_balance } },
          proc { |orders| orders.sum { |o| o.total } } ]
      when "payment_totals"
        [ proc { |orders| orders.first.payment_state },
          proc { |orders| orders.first.distributor.name },
          proc { |orders| orders.sum { |o| o.item_total } },
          proc { |orders| orders.sum { |o| o.ship_total } },
          proc { |orders| orders.sum { |o| o.total } },
          proc { |orders| orders.sum { |o| o.payments.select { |payment| payment.completed? && (payment.payment_method.name.to_s.include? "EFT") }.sum { |payment| payment.amount } } },
          proc { |orders| orders.sum { |o| o.payments.select { |payment| payment.completed? && (payment.payment_method.name.to_s.include? "PayPal") }.sum{ |payment| payment.amount } } },
          proc { |orders| orders.sum { |o| o.outstanding_balance } } ]
      else
        [ proc { |payments| payments.first.order.payment_state },
          proc { |payments| payments.first.order.distributor.name },
          proc { |payments| payments.first.payment_method.name },
          proc { |payments| payments.sum { |payment| payment.amount } } ]
      end
    end
  end
end
