# frozen_string_literal: true

module Api
  module Admin
    class EnterpriseFeeSerializer < ActiveModel::Serializer
      attributes :id, :enterprise_id, :fee_type, :name, :tax_category_id, :inherits_tax_category,
                 :calculator_type, :enterprise_name, :calculator_description, :calculator_settings

      def enterprise_name
        object.enterprise&.name
      end

      def calculator_description
        object.calculator&.description
      end

      def calculator_settings
        return nil unless options[:include_calculators]

        result = nil

        options[:controller].__send__(:with_format, :html) do
          result = options[:controller].
            render_to_string(partial: 'admin/enterprise_fees/calculator_settings',
                             locals: { enterprise_fee: object })
        end

        result.gsub('[0]', '[{{ $index }}]').gsub('_0_', '_{{ $index }}_')
      end
    end
  end
end
