# Helper class to allow accessing Spree's RABL templates from AMS
class Api::V0::RablSerializer

  # We need to find Spree API views
  VIEW_PATH = Spree::Api::Engine.paths["app/views"].to_a

  # need to define the +template+ method

  def initialize(obj, opts={})
    @obj = obj
  end

  def serializable_hash
    Rabl.render(@obj, template, format: 'hash', view_path: VIEW_PATH)
  end
end
