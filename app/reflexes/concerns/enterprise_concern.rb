# frozen_string_literal: true

module EnterpriseConcern
  extend ActiveSupport::Concern

  included do
    before_reflex do
      @enterprise = Enterprise.find_by(permalink: params[:id])
      authorize! :update, @enterprise
    end
  end
end
