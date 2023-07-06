# frozen_string_literal: true

class ProductsTableComponent < ViewComponentReflex::Component
  include Pagy::Backend

  SORTABLE_COLUMNS = ['name', 'import_date'].freeze
  SELECTABLE_COLUMNS = [
    { label: I18n.t("admin.products_page.columns_selector.price"), value: "price" },
    { label: I18n.t("admin.products_page.columns_selector.unit"), value: "unit" },
    { label: I18n.t("admin.products_page.columns_selector.producer"), value: "producer" },
    { label: I18n.t("admin.products_page.columns_selector.category"), value: "category" },
    { label: I18n.t("admin.products_page.columns_selector.sku"), value: "sku" },
    { label: I18n.t("admin.products_page.columns_selector.on_hand"), value: "on_hand" },
    { label: I18n.t("admin.products_page.columns_selector.on_demand"), value: "on_demand" },
    { label: I18n.t("admin.products_page.columns_selector.tax_category"), value: "tax_category" },
    {
      label: I18n.t("admin.products_page.columns_selector.inherits_properties"),
      value: "inherits_properties"
    },
    { label: I18n.t("admin.products_page.columns_selector.import_date"), value: "import_date" }
  ].sort do |a, b|
    a[:label] <=> b[:label]
  end.freeze

  PER_PAGE_VALUE = [10, 25, 50, 100].freeze
  PER_PAGE = PER_PAGE_VALUE.map { |value| { label: value, value: value } }
  NAME_COLUMN = {
    label: I18n.t("admin.products_page.columns.name"), value: "name", sortable: true
  }.freeze

  def initialize(user:)
    super
    @user = user
    @selectable_columns = SELECTABLE_COLUMNS
    @columns_selected = ['unit', 'price', 'on_hand', 'category', 'import_date']
    @per_page = PER_PAGE
    @per_page_selected = [10]
    @categories = [{ label: "All", value: "all" }] +
                  Spree::Taxon.order(:name)
                    .map { |taxon| { label: taxon.name, value: taxon.id.to_s } }
    @categories_selected = ["all"]
    @producers = [{ label: "All", value: "all" }] +
                 OpenFoodNetwork::Permissions.new(@user)
                   .managed_product_enterprises.is_primary_producer.by_name
                   .map { |producer| { label: producer.name, value: producer.id.to_s } }
    @producers_selected = ["all"]
    @page = 1
    @sort = { column: "name", direction: "asc" }
    @search_term = ""
  end

  # any change on a "reflex_data_attributes" (defined in the template) will trigger a re render
  def before_render
    fetch_products
    refresh_columns
  end

  # Element refers to the component the data is set on
  def search_term
    # Element is SearchInputComponent
    @search_term = element.dataset['value']
  end

  def toggle_column
    # Element is SelectorComponent
    column = element.dataset['value']
    @columns_selected = if @columns_selected.include?(column)
                          @columns_selected - [column]
                        else
                          @columns_selected + [column]
                        end
  end

  def click_sort
    # Element is TableHeaderComponent
    @sort = {
      column: element.dataset['sort-value'],
      direction: element.dataset['sort-direction'] == "asc" ? "desc" : "asc"
    }
  end

  def toggle_per_page
    # Element is SelectorComponent
    selected = element.dataset['value'].to_i
    @per_page_selected = [selected] if PER_PAGE_VALUE.include?(selected)
  end

  def toggle_category
    # Element is SelectorWithFilterComponent
    category_clicked = element.dataset['value']
    @categories_selected = toggle_selector_with_filter(category_clicked, @categories_selected)
  end

  def toggle_producer
    # Element is SelectorWithFilterComponent
    producer_clicked = element.dataset['value']
    @producers_selected = toggle_selector_with_filter(producer_clicked, @producers_selected)
  end

  def change_page
    # Element is PaginationComponent
    page = element.dataset['page'].to_i
    @page = page if page > 0
  end

  private

  def refresh_columns
    @columns = @columns_selected.map do |column|
      {
        label: I18n.t("admin.products_page.columns.#{column}"),
        value: column,
        sortable: SORTABLE_COLUMNS.include?(column)
      }
    end.sort! { |a, b| a[:label] <=> b[:label] }
    @columns.unshift(NAME_COLUMN)
  end

  def toggle_selector_with_filter(clicked, selected)
    selected = if selected.include?(clicked)
                 selected - [clicked]
               else
                 selected + [clicked]
               end

    if clicked == "all" || selected.empty?
      selected = ["all"]
    elsif selected.include?("all") && selected.length > 1
      selected -= ["all"]
    end
    selected
  end

  def fetch_products
    product_query = OpenFoodNetwork::Permissions.new(@user).editable_products.merge(product_scope)
    @products = product_query.ransack(ransack_query).result
    @pagy, @products = pagy(@products, items: @per_page_selected.first, page: @page)
  end

  def product_scope
    scope = if @user.has_spree_role?("admin") || @user.enterprises.present?
              Spree::Product
            else
              Spree::Product.active
            end

    scope.includes(product_query_includes)
  end

  def ransack_query
    query = { s: "#{@sort[:column]} #{@sort[:direction]}" }

    query = if @producers_selected.include?("all")
              query.merge({ supplier_id_eq: "" })
            else
              query.merge({ supplier_id_in: @producers_selected })
            end

    query = query.merge({ name_cont: @search_term }) if @search_term.present?

    if @categories_selected.include?("all")
      query.merge({ primary_taxon_id_eq: "" })
    else
      query.merge({ primary_taxon_id_in: @categories_selected })
    end
  end

  def product_query_includes
    [
      :image,
      variants: [
        :default_price,
        :stock_locations,
        :stock_items,
        :variant_overrides
      ]
    ]
  end
end
