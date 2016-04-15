module Admin
  class TagRulesController < ResourceController

    respond_to :json

    respond_override destroy: { json: {
      success: lambda { render nothing: true, :status => 204 }
    } }
  end
end
