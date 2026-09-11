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
        if postal_code_first?
          render_address([zipcode, city])
        else
          render_address([city, zipcode, state&.name])
        end
      end

      def full_address
        if postal_code_first?
          render_address([address1, address2, zipcode, city])
        else
          render_address([address1, address2, city, zipcode, state&.name])
        end
      end

      def blank?
        @data.nil?
      end

      private

      def postal_code_first?
        Spree::Config[:address_display_format] == "postal_code_first"
      end

      def render_address(address_parts)
        address_parts.compact_blank.join(', ')
      end
    end
  end
end
