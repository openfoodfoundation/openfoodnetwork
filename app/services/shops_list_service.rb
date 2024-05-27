# frozen_string_literal: true

class ShopsListService
  def open_shops(user) 

    if user      
      grouped_enterprises(user).ready_for_checkout
    else
      shops_list.ready_for_checkout.all  
    end
  end

  def closed_shops(user)
    if user
      grouped_enterprises(user).not_ready_for_checkout
    else
      shops_list.not_ready_for_checkout.all
    end
  end

  private

  def grouped_enterprises(user)
    Enterprise.grouped_enterprises_for_user(user)
  end

  def shops_list
    Enterprise
      .activated
      .is_distributor
      .includes(address: [:state, :country])
      .includes(:properties)
      .includes(supplied_products: :properties)
  end
end
