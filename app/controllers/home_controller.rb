class HomeController < BaseController
  layout 'landing_page'

  def new_landing_page
  end

  def about_us
  end

  def temp_landing_page
    @regions = []

    DISTRIBUTOR_CONFIG[Rails.env]["regions"].each do |region_data|
      region = {}
      region[:name] = region_data["name"]
      distributors = []
      region_data["distributors"].each do |distributor_data|
        enterprise = Enterprise.find_by_name(distributor_data["name"])
        distributors << enterprise if !enterprise.nil? && enterprise.is_distributor
      end
      region[:distributors] = distributors
      @regions << region
    end

    render layout: false
  end
end
