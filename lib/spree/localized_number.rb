module Spree
  class LocalizedNumber
    # This class overwrites the attribute setters of a model
    # to make them use the LocalizedNumber#parse method.
    # It works with ActiveRecord "normal" attributes
    # and Preference attributes.
    # It also adds a validation on the input format.

    attr_reader :model_class
    delegate :validate, :instance_method, :define_method, :table_exists?, :column_names, to: :model_class

    def initialize(model_class, attributes)
      @model_class = model_class
      @attributes = attributes
    end

    def setup
      validate :validate_localizable_number

      @attributes.each do |attribute|
        override_setter_for(attribute)
      end

      define_method(:validate_localizable_number) do
        return unless Spree::Config.enable_localized_number?
        @invalid_localized_number.andand.each do |error_attribute|
          errors.set(error_attribute, [I18n.t('spree.localized_number.invalid_format')])
        end
      end
    end

    def override_setter_for(attribute)
      setter = "#{attribute}="
      old_setter = instance_method(setter) if table_exists? && !column_names.include?(attribute.to_s)

      define_method(setter) do |number|
        validated_number = Spree::LocalizedNumber.validated_number(number)

        if validated_number.nil?
          @invalid_localized_number ||= []
          @invalid_localized_number << attribute
        end

        if has_attribute?(attribute)
          self[attribute] = validated_number
        else
          old_setter.bind(self).call(validated_number)
        end
      end
    end

    def self.validated_number(number)
      return parse(number) if valid_localizable_number?(number)
      nil
    end

    def self.valid_localizable_number?(number)
      return true unless number.is_a?(String) || number.respond_to?(:to_d)
      return false if number =~ /[\.,]\d{2}[\.,]/
      true
    end

    def self.parse(number)
      return nil if number.blank?
      return number.to_d unless number.is_a?(String)

      number = number.gsub(/[^\d.,-]/, '') # Replace all Currency Symbols, Letters and -- from the string

      add_trailing_zeros(number)

      number = number.gsub(/[\.,]/, '')    # Replace all (.) and (,) so the string result becomes in "cents"
      number.to_d / 100                    # Let to_decimal do the rest
    end

    def self.add_trailing_zeros(number)
      # If string ends in a single digit (e.g. ,2), make it ,20 in order for the result to be in "cents"
      number << "0" if number =~ /^.*[\.,]\d{1}$/

      # If does not end in ,00 / .00 then add trailing 00 to turn it into cents
      number << "00" unless number =~ /^.*[\.,]\d{2}$/
    end
  end
end
