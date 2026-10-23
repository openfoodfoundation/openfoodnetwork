# frozen_string_literal: false

class Invoice
  class CustomerSerializer < ActiveModel::Serializer
    attributes :code, :email, :customer_type, :enterprise_name, :enterprise_acn,
               :enterprise_abn, :enterprise_charges_sales_tax
  end
end
