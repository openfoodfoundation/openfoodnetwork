# frozen_string_literal: true

class ShopsController < BaseController
  layout 'darkswarm'

  def index
    user_enterprises = spree_current_user.enterprises

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
    @enterprises.merge(ShopsListService.new.open_shops)
  end
end
