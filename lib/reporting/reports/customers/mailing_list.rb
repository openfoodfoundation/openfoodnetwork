# frozen_string_literal: true

module Reporting
  module Reports
    module Customers
      class MailingList < Base
        def columns
          {
            email: proc { |order| order.email },
            first_name: proc { |order| order.billing_address.firstname },
            last_name: proc { |order| order.billing_address.lastname },
            suburb: proc { |order| order.billing_address.city },
          }
        end
      end
    end
  end
end
