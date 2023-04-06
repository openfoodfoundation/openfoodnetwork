# frozen_string_literal: true

module Reporting
  module Reports
    module Customers
      class MailingList < Base
        def query_result
          super.group_by do |order|
            {
              email: order.email,
              first_name: order.billing_address.firstname,
              last_name: order.billing_address.lastname,
              suburb: order.billing_address.city,
            }
          end.values.map(&:first)
        end

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
