class AngularTemplatesController < ApplicationController
  def show
    render params[:id].to_s, layout: nil
  end
end
