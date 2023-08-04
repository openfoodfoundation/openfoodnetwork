# frozen_string_literal: false

class Invoice
  class DataPresenter
    class Address < Invoice::DataPresenter::Base
      attributes :firstname, :lastname, :address1, :address2, :city, :zipcode, :company, :phone
      attributes_with_presenter :state
      invoice_generation_attributes :firstname, :lastname, :address1, :address2, :city, :zipcode,
                                    :company, :phone

      def full_name
        "#{firstname} #{lastname}".strip
      end

      def address_part1
        render_address([address1, address2])
      end

      def address_part2
        render_address([city, zipcode, state&.name])
      end

      def full_address
        render_address([address1, address2, city, zipcode, state&.name])
      end

      def blank?
        @data.nil?
      end

      private

      def render_address(address_parts)
        address_parts.compact_blank.join(', ')
      end
    end
  end
end
