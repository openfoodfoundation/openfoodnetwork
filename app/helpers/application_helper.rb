module ApplicationHelper
  def home_page_cms_content
    if controller.controller_name == 'home' && controller.action_name == 'index'
      cms_page_content(:content, Cms::Page.find_by_full_path('/'))
    end
  end


  def angular_form_for(name, *args, &block)
    options = args.extract_options!

    form_for(name, *(args << options.merge(:builder => AngularFormBuilder)), &block)
  end


  # Pass URL helper calls on to spree where applicable so that we don't need to use
  # spree.foo_path in any view rendered from non-spree-namespaced controllers.
  def method_missing(method, *args, &block)
    if (method.to_s.end_with?('_path') || method.to_s.end_with?('_url')) && spree.respond_to?(method)
      spree.send(method, *args)
    else
      super
    end
  end
end
