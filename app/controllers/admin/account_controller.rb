class Admin::AccountController < Spree::Admin::BaseController

  def show
    @enterprises = spree_current_user.owned_enterprises
    # .group_by('enterprise.id').joins(:billable_periods)
    # .select('SUM(billable_periods.turnover) AS turnover').order('turnover DESC')
  end
end
