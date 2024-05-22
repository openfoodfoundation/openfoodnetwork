# frozen_string_literal: true

class ShopsController < BaseController
  layout 'darkswarm'

  def index
    @enterprises = ShopsListService.new.open_shops
    
    user_enterprises = spree_current_user&.enterprises

    @grouped_enterprises = Set.new

    user_enterprises&.each do |enterprise|
      # Find all groups of the current enterprise
      groups = enterprise.groups

      # For each group associated with the current enterprise
      groups.each do |group|
        # Fetch all enterprises in that group with public visibility
        enterprises = group.enterprises.where(visible: 'public')

        # If the user's enterprise is private, include only public enterprises
        if enterprise.visible == 'private'
          @grouped_enterprises.merge(enterprises)
          @grouped_enterprises.merge([enterprise])
        else
          @grouped_enterprises.merge(enterprises)
        end
      end
    end

    @grouped_enterprises = @grouped_enterprises.to_a
  end
end
