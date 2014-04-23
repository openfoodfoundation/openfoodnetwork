
require_relative 'config'


module OpenFoodNetwork

  def self.config(&block)
    yield(OpenFoodNetwork::Config)
  end

  module Core
  end

end
