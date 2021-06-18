# frozen_string_literal: true

class GroupsController < BaseController
  layout 'darkswarm'

  def show
    enable_embedded_shopfront
    @hide_menu = true if @shopfront_layout == 'embedded'
    @group = EnterpriseGroup.find_by(permalink: params[:id]) || EnterpriseGroup.find(params[:id])
  end
end
