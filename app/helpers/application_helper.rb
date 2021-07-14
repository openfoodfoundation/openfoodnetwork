# frozen_string_literal: true

module ApplicationHelper
  include RawParams
  include Pagy::Frontend

  def feature?(feature, user = nil)
    OpenFoodNetwork::FeatureToggle.enabled?(feature, user)
  end

  def ng_form_for(name, *args, &block)
    options = args.extract_options!

    form_for(name, *(args << options.merge(builder: AngularFormBuilder)), &block)
  end

  # Pass URL helper calls on to spree where applicable so that we don't need to use
  # spree.foo_path in any view rendered from non-spree-namespaced controllers.
  def method_missing(method, *args, &block)
    if method.to_s.end_with?('_path', '_url') && spree.respond_to?(method)
      spree.public_send(method, *args)
    else
      super
    end
  end

  def body_classes
    classes = []
    classes << "off-canvas" unless @hide_menu
    classes << @shopfront_layout
  end
end
