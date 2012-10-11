module ApplicationHelper
  def home_page_cms_content
    if controller.controller_name == 'home' && controller.action_name == 'index'
      cms_page_content(:content, Cms::Page.find_by_full_path('/'))
    end
  end
end
