# frozen_string_literal: true

module TomSelectHelper
  def tomselect_open(field_name)
    page.find("##{field_name}-ts-control").click
  end

  def tomselect_multiselect(value, options)
    tomselect_wrapper = page.find("[name='#{options[:from]}']").sibling(".ts-wrapper")
    tomselect_wrapper.find(".ts-control").click
    tomselect_wrapper.find(:css, '.ts-dropdown.multi .ts-dropdown-content .option',
                           text: value).click
  end

  def tomselect_search_and_select(value, options)
    tomselect_wrapper = page.find("[name='#{options[:from]}']").sibling(".ts-wrapper")
    tomselect_wrapper.find(".ts-control").click
    # Use send_keys as setting the value directly doesn't trigger the search
    tomselect_wrapper.find(:css, '.ts-dropdown input.dropdown-input').send_keys(value)
    tomselect_wrapper.find(:css, '.ts-dropdown .ts-dropdown-content .option', text: value).click
  end

  def tomselect_select(value, options)
    tomselect_wrapper = page.find("[name='#{options[:from]}']").sibling(".ts-wrapper")
    tomselect_wrapper.find(".ts-control").click

    tomselect_wrapper.find(:css, '.ts-dropdown .ts-dropdown-content .option', text: value).click
  end

  def select_tom_select(value, from:)
    container = find(:id, from)

    within(container) do
      find('.ts-control').send_keys(value)
    end

    find('.ts-dropdown .ts-dropdown-content .option', text: /#{Regexp.quote(value)}/i).click
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
end
