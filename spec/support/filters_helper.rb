# frozen_string_literal: true

module OpenFoodNetwork
  # Helper for customer-facing filters (eg. producers, shops, groups, etc.)
  module FiltersHelper
    # Expand/collapse the filters dialog
    def toggle_filters
      find('a.filterbtn').click
    end

    # Toggle one particular filter
    def toggle_filter(name)
      page.find('span', text: name).click
    end
  end
end
