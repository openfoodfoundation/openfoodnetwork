# frozen_string_literal: true

# Processes requests for pages embedded in iframes

class EmbeddedPageService
  attr_reader :embedding_domain, :use_embedded_layout

  def initialize(params, session, request, response)
    @params = params
    @session = session
    @request = request
    @response = response

    @embedding_domain = @session[:embedding_domain]
    @use_embedded_layout = false
  end

  def embed!
    return unless embeddable?
    return if embedding_without_https?

    process_embedded_request
    set_embedded_layout
  end

  private

  def embeddable?
    return true if current_referer == @request.host

    domain = current_referer_without_www
    whitelist = Spree::Config[:embedded_shopfronts_whitelist]

    embedding_enabled? && whitelist.present? && domain.present? && whitelist.include?(domain)
  end

  def embedding_without_https?
    @request.referer && URI(@request.referer).scheme != 'https' &&
      !Rails.env.test? && !Rails.env.development?
  end

  def process_embedded_request
    return unless @params[:embedded_shopfront]

    set_embedding_domain

    @session[:embedded_shopfront] = true
    set_logout_redirect
  end

  def set_embedding_domain
    return unless @params[:embedded_shopfront]
    return if current_referer == @request.host

    @embedding_domain = current_referer
    @session[:embedding_domain] = current_referer
  end

  def set_logout_redirect
    return unless enterprise_slug

    @session[:shopfront_redirect] = '/' + enterprise_slug + '/shop?embedded_shopfront=true'
  end

  def enterprise_slug
    return false unless @params[:controller] == 'enterprises' &&
                        @params[:action] == 'shop' && @params[:id]

    @params[:id]
  end

  def current_referer
    uri = URI.parse(@request.referer)
    return unless uri.is_a?(URI::HTTP) && uri.host.present?

    uri.host.downcase
  rescue URI::InvalidURIError
    false
  end

  def current_referer_without_www
    return unless current_referer

    current_referer.start_with?('www.') ? current_referer[4..-1] : current_referer
  end

  def set_embedded_layout
    return unless @session[:embedded_shopfront]

    @use_embedded_layout = true
  end

  def embedding_enabled?
    Spree::Config[:enable_embedded_shopfronts]
  end
end
