class MenuURL
  ROUTES = {
    menu_1: Rails.application.routes.url_helpers.shops_path,
    menu_2: Rails.application.routes.url_helpers.map_path,
    menu_3: Rails.application.routes.url_helpers.producers_path,
    menu_4: Rails.application.routes.url_helpers.groups_path
  }.freeze

  def initialize(id)
    @id = id.to_sym
    @key = "#{id}_url".upcase.freeze
  end

  def to_s
    ENV.fetch(key, ROUTES.fetch(id))
  end

  private

  attr_reader :id, :key
end
