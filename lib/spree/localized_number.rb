# frozen_string_literal: true

module Spree
  module LocalizedNumber
    # This method overwrites the attribute setters of a model
    # to make them use the LocalizedNumber parsing method.
    # It works with ActiveRecord "normal" attributes
    # and Preference attributes.
    # It also adds a validation on the input format.
    # It accepts as arguments a variable number of attribute as symbols
    def localize_number(*attributes)
      validate :validate_localizable_number

      attributes.each do |attribute|
        setter = "#{attribute}="
        old_setter = instance_method(setter) if non_activerecord_attribute?(attribute)

        define_method(setter) do |number|
          if Spree::Config.enable_localized_number? &&
             Spree::LocalizedNumber.valid_localizable_number?(number)
            number = Spree::LocalizedNumber.parse(number)
          elsif Spree::Config.enable_localized_number?
            @invalid_localized_number ||= []
            @invalid_localized_number << attribute
            number = nil unless is_a?(Spree::Calculator)
          end
          if has_attribute?(attribute)
            # In this case it's a regular AR attribute with standard setters
            self[attribute] = number
          else
            # In this case it's a Spree preference, and the interface is very different
            old_setter.bind(self).call(number)
          end
        end
      end

      define_method(:validate_localizable_number) do
        return unless Spree::Config.enable_localized_number?

        @invalid_localized_number&.each do |error_attribute|
          errors.add(error_attribute, I18n.t('spree.localized_number.invalid_format'))
        end
      end
    end

    def self.valid_localizable_number?(number)
      return true unless number.is_a?(String) || number.respond_to?(:to_d)
      # Invalid if only two digits between dividers, or if any non-number characters
      return false if number.to_s =~ /[.,]\d{2}[.,]/ || number.to_s =~ /[^-0-9,.]+/

      true
    end

    def self.parse(number)
      return nil if number.blank?
      return number.to_d unless number.is_a?(String)

      # Replace all Currency Symbols, Letters and -- from the string
      number = number.gsub(/[^\d.,-]/, '')

      add_trailing_zeros(number)

      # Replace all (.) and (,) so the string result becomes in "cents"
      number = number.gsub(/[.,]/, '')
      number.to_d / 100 # Let to_decimal do the rest
    end

    def self.add_trailing_zeros(number)
      # If string ends in a single digit (e.g. ,2), make it
      # ,20 in order for the result to be in "cents"
      number << "0" if number =~ /^.*[.,]\d{1}$/

      # If does not end in ,00 / .00 then add trailing 00 to turn it into cents
      number << "00" unless number =~ /^.*[.,]\d{2}$/
    end

    private

    def non_activerecord_attribute?(attribute)
      table_exists? && !column_names.include?(attribute.to_s)
    rescue ::ActiveRecord::NoDatabaseError
      # This class is now loaded during `rake db:create` (since Rails 5.2), and not only does the
      # table not exist, but the database does not even exist yet, and throws a fatal error.
      # We can rescue and safely ignore it in that case.
    end
  end
end
