class HomeController < BaseController
  layout 'landing_page'

  def new_landing_page
  end

  def about_us
  end

  def temp_landing_page
    @groups = EnterpriseGroup.on_front_page

    render layout: false
  end
end
