# frozen_string_literal: true

module TomSelectHelper
  def tomselect_multiselect(value, options)
    tomselect_wrapper = page.find_field(options[:from]).sibling(".ts-wrapper")
    tomselect_wrapper.find(".ts-control").click
    tomselect_wrapper.find(:css, ".ts-dropdown.multi .ts-dropdown-content .option",
                           text: value).click
    # Close the dropdown
    page.find("body").click
  end

  # Allows adding new values that are not included in the list of possible options
  def tomselect_fill_in(selector, with:)
    tomselect_wrapper = page.find_field(selector).sibling(".ts-wrapper")
    tomselect_wrapper.find(".ts-control").click
    # Use send_keys as setting the value directly doesn't trigger the search
    tomselect_wrapper.find(:css, '.ts-dropdown input.dropdown-input').send_keys(with)
    tomselect_wrapper.find(:css, '.ts-dropdown div.create').click
  end

  # Searches for and selects an option in a TomSelect dropdown with search functionality.
  # @param value [String] The text to search for and select from the dropdown
  # @param options [Hash] Configuration options
  # @option options [String] :from The name/id of the select field
  # @option options [Boolean] :remote_search If true, waits for search loading after interactions
  #
  # @example
  #   tomselect_search_and_select("Apple", from: "fruit_selector")
  #   tomselect_search_and_select("California", from: "state", remote_search: true)
  def tomselect_search_and_select(value, options)
    tomselect_wrapper = page.find_field(options[:from]).sibling(".ts-wrapper")
    tomselect_wrapper.find(".ts-control").click
    expect_tomselect_loading_completion(tomselect_wrapper, options)

    # Use send_keys as setting the value directly doesn't trigger the search
    tomselect_wrapper.find(".ts-dropdown input.dropdown-input").send_keys(value)
    expect_tomselect_loading_completion(tomselect_wrapper, options)

    tomselect_wrapper.find(".ts-dropdown .ts-dropdown-content .option", text: value).click
  end

  def tomselect_select(value, options)
    tomselect_wrapper = page.find_field(options[:from]).sibling(".ts-wrapper")
    tomselect_wrapper.find(".ts-control").click

    tomselect_wrapper.find(".ts-dropdown .ts-dropdown-content .option", text: value).click
  end

  def open_tomselect_to_validate!(page, field_name)
    tomselect_wrapper = page.find_field(field_name).sibling(".ts-wrapper")
    tomselect_wrapper.find(".ts-control").click # open the dropdown

    raise "Please pass the block for expectations" unless block_given?

    # execute block containing expectations
    yield

    tomselect_wrapper.find(
      ".ts-dropdown .ts-dropdown-content .option.active",
    ).click # close the dropdown by selecting the already selected value
  end

  def expect_tomselect_selected_options(from, *options)
    tomselect_control = page
      .find("[name='#{from}']")
      .sibling(".ts-wrapper")
      .find('.ts-control')

    within(tomselect_control) do
      # options in case of we want to expect multiselect options
      options.each do |option|
        expect(page).to have_css(
          "div[data-ts-item]",
          text: option
        )
      end
    end
  end

  # Validates both available options and selected options in a TomSelect dropdown.
  # @param from [String] The name/id of the select field
  # @param existing_options [Array<String>] List of options that should be available in the dropdown
  # @param selected_options [Array<String>] List of options that should currently be selected
  #
  # @example
  #   expect_tomselect_existing_with_selected_options(
  #     from: "category_selector",
  #     existing_options: ["Fruit", "Vegetables", "Dairy"],
  #     selected_options: ["Fruit"]
  #   )
  def expect_tomselect_existing_with_selected_options(from:, existing_options:, selected_options:)
    tomselect_wrapper = page.find_field(from).sibling(".ts-wrapper")
    tomselect_control = tomselect_wrapper.find('.ts-control')

    tomselect_control.click # open the dropdown (would work for remote vs non-remote dropdowns)

    # validate existing options are present in the dropdown
    within(tomselect_wrapper) do
      existing_options.each do |option|
        expect(page).to have_css(
          ".ts-dropdown .ts-dropdown-content .option",
          text: option
        )
      end
    end

    # validate selected options are selected in the dropdown
    within(tomselect_wrapper) do
      selected_options.each do |option|
        expect(page).to have_css(
          "div[data-ts-item]",
          text: option
        )
      end
    end

    # close the dropdown by clicking on the already selected option
    tomselect_wrapper.find(".ts-dropdown .ts-dropdown-content .option.active").click
  end

  def expect_tomselect_loading_completion(tomselect_wrapper, options)
    return unless options[:remote_search]

    expect(tomselect_wrapper).to have_css(".spinner")
    expect(tomselect_wrapper).not_to have_css(".spinner")
  end
end
