module EnterprisesHelper
  def current_distributor
    @current_distributor ||= current_order(false).andand.distributor
  end
  
  def enterprises_options enterprises
    enterprises.map { |enterprise| [enterprise.name + ": " + enterprise.address.address1 + ", " + enterprise.address.city, enterprise.id.to_i] }
  end
end
