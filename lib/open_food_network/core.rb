
require 'open_food_network/config'

puts 'OpenFoodNetwork!'
module OpenFoodNetwork

  def self.config(&block)
    yield(OpenFoodNetwork::Config)
  end

  module Core
  end

end
