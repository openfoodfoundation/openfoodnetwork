# frozen_string_literal: true

module ApplicationHelper
  include RawParams
  include Pagy::Frontend

  def error_message_on(object, method, options = {})
    object = convert_to_model(object)
    obj = object.respond_to?(:errors) ? object : instance_variable_get("@#{object}")

    return "" unless obj && obj.errors[method].present?

    errors = obj.errors[method].map { |err| h(err) }.join('<br />').html_safe # rubocop:disable Rails/OutputSafety

    if options[:standalone]
      content_tag(
        :div,
        content_tag(:span, errors, class: 'formError standalone'),
        class: 'checkout-input'
      )
    else
      content_tag(:span, errors, class: 'formError')
    end
  end

  # Checks weather a feature is enabled for any of the given actors.
  def feature?(feature, *actors)
    OpenFoodNetwork::FeatureToggle.enabled?(feature, *actors)
  end

  def language_meta_tags
    return if I18n.available_locales.one?

    I18n.available_locales.map do |locale|
      tag.link(
        hreflang: locale.to_s.gsub("_", "-").downcase,
        href: "#{request.protocol}#{request.host_with_port}/locales/#{locale}"
      )
    end.join("\n").html_safe # rubocop:disable Rails/OutputSafety
  end

  def ng_form_for(name, *args, &)
    options = args.extract_options!

    form_for(name, *(args << options.merge(builder: AngularFormBuilder)), &)
  end

  def respond_to_missing?(method_name, include_private = false)
    (method_name.to_s.end_with?('_path',
                                '_url') && spree.respond_to?(method_name, include_private)) || super
  end

  # Pass URL helper calls on to spree where applicable so that we don't need to use
  # spree.foo_path in any view rendered from non-spree-namespaced controllers.
  def method_missing(method, *args, &)
    if method.to_s.end_with?('_path', '_url') && spree.respond_to?(method)
      spree.public_send(method, *args)
    else
      super
    end
  end

  def body_classes(hide_menu, shopfront_layout)
    classes = []
    classes << "off-canvas" unless hide_menu
    classes << shopfront_layout
  end

  def cache_with_locale(key = nil, options = {}, &block)
    cache(cache_key_with_locale(key, I18n.locale), options) do
      yield(block)
    end
  end

  def cache_key_with_locale(key, locale)
    Array.wrap(key) + [locale.to_s, I18nDigests.for_locale(locale)]
  end
end
