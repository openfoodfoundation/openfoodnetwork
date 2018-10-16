module Web
  class AngularTemplatesController < ApplicationController
    helper Web::Engine.helpers

    def show
      render params[:id].to_s, layout: nil
    end
  end
end
