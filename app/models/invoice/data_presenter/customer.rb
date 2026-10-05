# frozen_string_literal: false

class Invoice
  class DataPresenter
    class Customer < Invoice::DataPresenter::Base
      attributes :code, :email, :customer_type, :enterprise_name, :enterprise_acn, :enterprise_abn,
                 :enterprise_charges_sales_tax

      def enterprise?
        customer_type == "enterprise"
      end
    end
  end
end
