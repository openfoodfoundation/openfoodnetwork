# frozen_string_literal: true

module DfcProvider
  class SocialMediasController < DfcProvider::ApplicationController
    before_action :check_enterprise

    def show
      name = params.require(:id)
      social_media = SocialMediaBuilder.social_media(current_enterprise, name)

      return not_found unless social_media

      render json: DfcIo.export(social_media)
    end
  end
end
