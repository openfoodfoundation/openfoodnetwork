module ApplicationHelper
  include FoundationRailsHelper::FlashHelper

  def feature?(feature)
    OpenFoodNetwork::FeatureToggle.enabled? feature
  end

  def ng_form_for(name, *args, &block)
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
