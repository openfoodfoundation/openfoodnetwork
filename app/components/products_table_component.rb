# frozen_string_literal: true

class ProductsTableComponent < ViewComponentReflex::Component
  include Pagy::Backend

  SORTABLE_COLUMNS = ["name"].freeze

  def initialize(user:)
    super
    @user = user
    @selectable_columns = [{ label: I18n.t("admin.products_page.columns_selector.price"),
                             value: "price" },
                           { label: I18n.t("admin.products_page.columns_selector.unit"),
                             value: "unit" },
                           { label: I18n.t("admin.products_page.columns_selector.producer"),
                             value: "producer" },
                           { label: I18n.t("admin.products_page.columns_selector.category"),
                             value: "category" }].sort { |a, b|
      a[:label] <=> b[:label]
    }
    @columns_selected = ["price", "unit"]
    @per_page = [{ label: "10", value: 10 }, { label: "25", value: 25 }, { label: "50", value: 50 },
                 { label: "100", value: 100 }]
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
  end

  def before_render
    fetch_products
    refresh_columns
  end

  def toggle_column
    column = element.dataset['value']
    @columns_selected = if @columns_selected.include?(column)
                          @columns_selected - [column]
                        else
                          @columns_selected + [column]
                        end
  end

  def click_sort
    @sort = { column: element.dataset['sort-value'],
              direction: element.dataset['sort-direction'] == "asc" ? "desc" : "asc" }
  end

  def toggle_per_page
    selected = element.dataset['value'].to_i
    @per_page_selected = [selected] if [10, 25, 50, 100].include?(selected)
  end

  def toggle_category
    category_clicked = element.dataset['value']
    @categories_selected = toggle_super_selector(category_clicked, @categories_selected)
  end

  def toggle_producer
    producer_clicked = element.dataset['value']
    @producers_selected = toggle_super_selector(producer_clicked, @producers_selected)
  end

  def change_page
    page = element.dataset['page'].to_i
    @page = page if page > 0
  end

  private

  def refresh_columns
    @columns = @columns_selected.map { |column|
      { label: I18n.t("admin.products_page.columns.#{column}"), value: column,
        sortable: SORTABLE_COLUMNS.include?(column) }
    }.sort! { |a, b| a[:label] <=> b[:label] }
    @columns.unshift({ label: I18n.t("admin.products_page.columns.name"), value: "name",
                       sortable: SORTABLE_COLUMNS.include?("name") })
  end

  def toggle_super_selector(clicked, selected)
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

    if @categories_selected.include?("all")
      query.merge({ primary_taxon_id_eq: "" })
    else
      query.merge({ primary_taxon_id_in: @categories_selected })
    end
  end

  def product_query_includes
    [
      master: [:images],
      variants: [:default_price, :stock_locations, :stock_items, :variant_overrides,
                 { option_values: :option_type }]
    ]
  end
end
