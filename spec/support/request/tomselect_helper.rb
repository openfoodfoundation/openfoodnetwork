# frozen_string_literal: true

module TomselectHelper
  def tomselect_open(field_name)
    page.find("##{field_name}-ts-control").click
  end

  def tomselect_multiselect(value, options)
    tomselect_wrapper = page.find_field(options[:from]).sibling(".ts-wrapper")
    tomselect_wrapper.find(".ts-control").click
    tomselect_wrapper.find(:css, '.ts-dropdown.multi .ts-dropdown-content .option',
                           text: value).click
    # Close the dropdown
    page.find("body").click
  end

  def tomselect_search_and_select(value, options)
    tomselect_wrapper = page.find_field(options[:from]).sibling(".ts-wrapper")
    tomselect_wrapper.find(".ts-control").click
    # Use send_keys as setting the value directly doesn't trigger the search
    tomselect_wrapper.find(:css, '.ts-dropdown input.dropdown-input').send_keys(value)
    tomselect_wrapper.find(:css, '.ts-dropdown .ts-dropdown-content .option', text: value).click
  end

  def tomselect_select(value, options)
    tomselect_wrapper = page.find_field(options[:from]).sibling(".ts-wrapper")
    tomselect_wrapper.find(".ts-control").click

    tomselect_wrapper.find(:css, '.ts-dropdown .ts-dropdown-content .option', text: value).click
  end

  def open_tomselect_to_validate!(page, field_name)
    tomselect_wrapper = page.find_field(field_name).sibling(".ts-wrapper")
    tomselect_wrapper.find(".ts-control").click # open the dropdown

    raise 'Please pass the block for expectations' unless block_given?

    # execute block containing expectations
    yield

    tomselect_wrapper.find(
      '.ts-dropdown .ts-dropdown-content .option.active',
    ).click # close the dropdown by selecting the already selected value
  end
end
