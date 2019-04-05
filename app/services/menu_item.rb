class MenuItem
  DEFAULT_ROUTES = {
    menu_1: Rails.application.routes.url_helpers.shops_path,
    menu_2: Rails.application.routes.url_helpers.map_path,
    menu_3: Rails.application.routes.url_helpers.producers_path,
    menu_4: Rails.application.routes.url_helpers.groups_path
  }.freeze

  def initialize(index)
    @index = index
    @id = "menu_#{index}".to_sym
    @key = "#{id}_url"
  end

  # Returns the URL of the menu item as String. Note that only the 4 items are
  # customizable through ENV vars. From the 5th onwards they will be fetched
  # from translations instead.
  #
  # The reasoning behind this is that new instances rarely customize the first
  # 4 in the beginning and tend to translate their URLs when they shouldn't.
  # The app only has URLs in English.
  def url
    if [*1..4].include?(index)
      ENV.fetch(key.upcase, DEFAULT_ROUTES.fetch(id))
    elsif [*5..7].include?(index)
      I18n.t(key)
    else
      raise KeyError
    end
  end

  def name
    id.to_s
  end

  def title
    I18n.t("#{name}_title")
  end

  private

  attr_reader :index, :id, :key
end
