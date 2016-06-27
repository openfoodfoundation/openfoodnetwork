module OpenFoodNetwork
  class PropertyMerge
    def self.merge(primary, secondary)
      primary + secondary.reject do |secondary_p|
        primary.any? do |primary_p|
          property_of(primary_p).presentation == property_of(secondary_p).presentation
        end
      end
    end


    private

    def self.property_of(p)
      p.respond_to?(:property) ? p.property : p
    end
  end
end
