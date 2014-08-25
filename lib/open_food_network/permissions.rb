module OpenFoodNetwork
  class Permissions
    def initialize(user)
      @user = user
    end

    def order_cycle_producers
      managed_producers
    end


    private

    def managed_producers
      Enterprise.managed_by(@user).is_primary_producer.by_name
    end

  end
end
