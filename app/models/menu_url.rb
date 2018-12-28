class MenuURL
  ROUTES = {
    menu_1: Rails.application.routes.url_helpers.shops_path,
    menu_2: Rails.application.routes.url_helpers.map_path
  }.freeze

  def initialize(key)
    @key = key.to_sym
  end

  def to_s
    ROUTES.fetch(key)
  end

  private

  attr_reader :key
end
