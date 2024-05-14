# frozen_string_literal: true

class ShopsController < BaseController
  layout 'darkswarm'

  def index
    return unless spree_current_user.present?
    
    user_enterprises = spree_current_user.enterprises.activated
    .visible
    .is_distributor
    .includes(address: [:state, :country])
    .includes(:properties)
    .includes(supplied_products: :properties)

    @enterprises = Set.new

    user_enterprises.each do |enterprise|
      # Find all groups of the current enterprise
      groups = enterprise.groups

      # For each group associated with the current enterprise
      groups.each do |group|
        # Fetch all enterprises in that group with public visibility
        enterprises = group.enterprises.where(visible: 'public')

        # If the user's enterprise is private, include only public enterprises
        if enterprise.visible == 'private'
          @enterprises.merge(enterprises)
        else
          @enterprises.merge(group.enterprises)
        end
      end
    end
  end
end
