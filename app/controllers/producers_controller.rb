class ProducersController < BaseController
  layout 'darkswarm'
  
  def index
    @producers = Enterprise.is_primary_producer.visible
  end
end
