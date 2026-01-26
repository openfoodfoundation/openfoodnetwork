# frozen_string_literal: true

module ProductsHelper
  def create_products(amount)
    amount.times do |i|
      create(:simple_product, name: "product #{i}", supplier_id: producer.id)
    end
  end

  def expect_page_to_be(page_number)
    expect(page).to have_selector ".pagination .page.current", text: page_number.to_s
  end

  def expect_per_page_to_be(per_page)
    expect(page).to have_selector "#per_page", text: per_page.to_s
  end

  def expect_products_count_to_be(count)
    expect(page).to have_selector("table.products tbody", count:)
  end

  def search_for(term)
    fill_in "search_term", with: term
    click_button "Search"
  end

  def search_by_producer(producer)
    tomselect_select producer, from: "producer_id"
    click_button "Search"
  end

  def search_by_category(category)
    tomselect_select category, from: "category_id"
    click_button "Search"
  end

  def search_by_tag(*tags)
    if tags.empty?
      raise ArgumentError, "Please provide at least one tag to search for"
    end

    tags.each { |tag| tomselect_multiselect tag, from: "tags_name_in" }
    click_button "Search"
  end

  # Selector for table row that has an input with this value.
  # Because there are no visible labels, the user has to assume which product it is, based on the
  # visible name.
  def row_containing_name(value)
    "tr:has(input[aria-label=Name][value='#{value}'])"
  end

  # Selector for table row that has an input with a placeholder.
  # Variant don't have display_name set, so we look for the input with placeholder matching the
  # product's name to get the variant row
  def row_containing_placeholder(value)
    "tr:has(input[aria-label=Name][placeholder='#{value}'])"
  end

  # Wait for an element with the given CSS selector and class to be present
  def wait_for_class(selector, class_name)
    max_wait_time = Capybara.default_max_wait_time
    Timeout.timeout(max_wait_time) do
      sleep(0.1) until page.has_css?(selector, class: class_name, visible: false)
    end
  end

  def expect_page_to_have_image(url)
    expect(page).to have_selector("img[src$='#{url}']")
  end

  def tax_category_column
    @tax_category_column ||= '[data-controller="variant"] > td:nth-child(10)'
  end

  def validate_tomselect_without_search!(page, field_name, search_selector)
    open_tomselect_to_validate!(page, field_name) do
      expect(page).not_to have_selector(search_selector)
    end
  end

  def validate_tomselect_with_search!(page, field_name, search_selector)
    open_tomselect_to_validate!(page, field_name) do
      expect(page).to have_selector(search_selector)
    end
  end

  def random_producer(product)
    Enterprise.is_primary_producer
      .where.not(id: product.supplier.id)
      .pluck(:name).sample
  end

  def random_category(variant)
    Spree::Taxon
      .where.not(id: variant.primary_taxon.id)
      .pluck(:name).sample
  end

  def random_tax_category
    Spree::TaxCategory
      .pluck(:name).sample
  end

  def all_input_values
    page.find_all('input[type=text]').map(&:value).join
  end

  def click_product_clone(product_name)
    within row_containing_name(product_name) do
      page.find(".vertical-ellipsis-menu").click
      click_link('Clone')
    end
  end
end
