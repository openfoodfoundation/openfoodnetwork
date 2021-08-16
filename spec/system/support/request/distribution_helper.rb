# frozen_string_literal: true

module OpenFoodNetwork
  module DistributionHelper
    def select_distribution(distributor, order_cycle = nil)
      create_enterprise_group_for distributor
      visit root_path
      click_link distributor.name

      if order_cycle && page.has_select?('order_order_cycle_id')
        select_by_value order_cycle.id, from: 'order_order_cycle_id'
      end
    end
  end
end
