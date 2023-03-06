# frozen_string_literal: true

module WebHelper
  def have_input(name, opts = {})
    selector  = "[name='#{name}']"
    selector += "[placeholder='#{opts[:placeholder]}']" if opts.key? :placeholder

    visible = opts.key?(:visible) ? opts[:visible] : true

    element = page.all(selector, visible: visible).first
    expect(element.value).to eq(opts[:with]) if element && opts.key?(:with)

    have_selector selector, visible: visible
  end

  def select_by_value(value, options = {})
    from = options.delete :from
    page.find_by(id: from).find("option[value='#{value}']").select_option
  end

  def flash_message
    find('.flash', visible: false).text(:all).strip
  end

  def handle_js_confirm(accept = true)
    page.execute_script "window.confirm = function(msg) { return #{!!accept}; }"
    yield
  end

  def set_i18n_locale(locale = 'en')
    page.execute_script("I18n.locale = '#{locale}'")
  end

  def get_i18n_locale
    page.evaluate_script("I18n.locale;")
  end

  def get_i18n_translation(key = nil)
    page.evaluate_script("I18n.t('#{key}');")
  end

  # http://www.elabs.se/blog/53-why-wait_until-was-removed-from-capybara
  # Do not use this without good reason. Capybara's built-in waiting is very effective.
  def wait_until(secs = nil)
    require "timeout"
    Timeout.timeout(secs || Capybara.default_max_wait_time) do
      sleep(0.1) until value = yield
      value
    end
  end

  def within_row(num, &block)
    within("table.index tbody tr:nth-child(#{num})", &block)
  end

  def select2_select(value, options)
    open_select2("#s2id_#{options[:from]}")

    if options[:search]
      page.find(:xpath, '//body')
        .find(:css, '.select2-drop-active input.select2-input, .select2-dropdown-open input.select2-input')
        .set(value)
    end

    page.find(:xpath, '//body')
      .find(:css, '.select2-drop-active .select2-result-label', text: options[:select_text] || value)
      .click

    expect(page).to have_select2 options[:from], selected: options[:select_text] || value
  end

  def open_select2(selector)
    page.find(selector).scroll_to(page.find(selector)).find(:css,
                                                            '.select2-choice, .select2-search-field').click
  end

  def close_select2
    # A click outside the select2 container should close it
    page.find(:css, 'body').click
  end

  def click_on_select2(value, options)
    find("#s2id_#{options[:from]}").click
    find(:css, ".select2-result-label", text: options[:select_text] || value).click
  end

  def tomselect_search_and_select(value, options)
    tomselect_wrapper = page.find("[name='#{options[:from]}']").sibling(".ts-wrapper")
    tomselect_wrapper.find(".ts-control").click
    tomselect_wrapper.find(:css, '.ts-dropdown input.dropdown-input').set(value)
    tomselect_wrapper.find(".ts-control").click
    tomselect_wrapper.find(:css, '.ts-dropdown .ts-dropdown-content .option', text: value).click
  end

  def request_monitor_finished(controller = nil)
    page.evaluate_script("#{angular_scope(controller)}.scope().RequestMonitor.loading == false")
  end

  def fill_in_tag(tag_name, selector = "tags-input .tags input")
    expect(page).to have_selector selector
    find(:css, selector).click
    find(:css, selector).set "#{tag_name}\n"
    expect(page).to have_selector ".tag-list .tag-item span", text: tag_name
  end

  private

  # Takes an optional angular controller name eg: "LineItemsCtrl",
  # otherwise finds the first object in the DOM with an angular scope
  def angular_scope(controller = nil)
    element = controller ? "[ng-controller=#{controller}]" : '.ng-scope'
    "angular.element(document.querySelector('#{element}'))"
  end
end
