# frozen_string_literal: true

class GroupsController < BaseController
  include EmbeddedPages

  layout 'darkswarm'

  def show
    @hide_menu = true if @shopfront_layout == 'embedded'
    @group = EnterpriseGroup.find_by(permalink: params[:id]) || EnterpriseGroup.find(params[:id])
  end
end
