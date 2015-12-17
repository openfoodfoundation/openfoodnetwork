# We need to have Spree's API controller for all the helper methods. But this also
# means that ActiveModel::Serializer isn't loaded. This class works around that.
class Api::V0::BaseController < Spree::Api::BaseController
  include ActionController::Serialization

  # Needed for ActiveModel::Serializer, and to use url helpers
  def url_options
    {host: request.host_with_port}
  end

  private

  def render(*args, **opts)
    if obj = opts.delete(:json)
      data = ActiveModel::Serializer.build_json(self, obj, **opts).as_json
      data.merge!(data.delete(:meta) || {}) unless opts[:meta_key] # meta in root by default
      super text: data.to_json, content_type: 'application/json'
    else
      super *args, **opts
    end
  end

  def render_collection(scope, **opts)
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 20).to_i # @todo default from model
    collection = scope.page(page).per(per_page)
    render({
        json: collection,
        meta: {
          count: collection.count,
          total_count: scope.count,
          current_page: page,
          pages: (scope.count * 1.0 / per_page).ceil
        }.merge(opts[:meta]||{})
      }.merge(opts))
  end
end
