# frozen_string_literal: true

module TimezoneAttributes
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def define_timezone_attribute_methods(enterprise, methods)
      methods.each do |method|
        define_method(method) do
          Time.use_zone(__send__(enterprise)&.timezone) { super() }
        end

        define_method("#{method}=") do |time|
          Time.use_zone(__send__(enterprise)&.timezone) do
            time ? super(Time.zone.parse(time.to_s)) : super(time)
          end
        end
      end
    end
  end
end
