# frozen_string_literal: true

module EmbeddedPages
  extend ActiveSupport::Concern

  included do
    content_security_policy do |policy|
      policy.frame_ancestors :self, -> { embed_service.embedding_domain }
    end

    before_action :enable_embedded_pages
  end

  private

  def enable_embedded_pages
    return unless embed_service.use_embedded_layout

    @shopfront_layout = 'embedded'
  end

  def embed_service
    @embed_service ||= EmbeddedPageService.
      new(params, session, request, response).
      tap(&:embed!)
  end
end
