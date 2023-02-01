# frozen_string_literal: true

module Api
  module Admin
    class EnterpriseFeeSerializer < ActiveModel::Serializer
      attributes :id, :enterprise_id, :fee_type, :name, :tax_category_id, :inherits_tax_category,
                 :calculator_type, :enterprise_name, :calculator_description

      def enterprise_name
        object.enterprise&.name
      end

      def calculator_description
        object.calculator&.description
      end
    end
  end
end
