module TimezoneAttributes
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def define_timezone_attribute_methods(enterprise, methods)
      methods.each do |method|
        define_method(method) do
          Time.use_zone(self.__send__(enterprise).timezone) do
            super()
          end
        end

        define_method("#{method}=") do |time|
          Time.use_zone(self.__send__(enterprise).timezone) do
            super(Time.zone.parse(time))
          end
        end
      end
    end
  end
end
