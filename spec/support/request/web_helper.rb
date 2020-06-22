module WebHelper
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    # By default, Capybara uses a 30 s wait time, which is more reliable for CI, but too slow
    # for TDD. Use this to make tests fail fast. Usage:
    #
    # describe "foo" do
    #   use_short_wait
    #   ...
    # end
    def use_short_wait(seconds = 2)
      around { |example| Capybara.using_wait_time(seconds) { example.run } }
    end
  end

  def have_input(name, opts = {})
    selector  = "[name='#{name}']"
    selector += "[placeholder='#{opts[:placeholder]}']" if opts.key? :placeholder

    element = page.all(selector).first
    expect(element.value).to eq(opts[:with]) if element && opts.key?(:with)

    have_selector selector
  end

  def fill_in_fields(field_values)
    field_values.each do |key, value|
      begin
        fill_in key, with: value
      rescue Capybara::ElementNotFound
        find_field(key).select(value)
      end
    end
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

  def visit_delete(url)
    response = Capybara.current_session.driver.delete url
    click_link 'redirected' if response.status == 302
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

  # Fetch the content of a script block
  # eg. script_content with: 'my-script.com'
  # Returns nil if not found
  # Raises an exception if multiple matching blocks are found
  def script_content(opts = {})
    elems = page.all('script', visible: false)

    elems = elems.to_a.select { |e| e.text(:all).include? opts[:with] } if opts[:with]

    if elems.none?
      nil
    elsif elems.many?
      raise "Multiple results returned for script_content"
    else
      elems.first.text(:all)
    end
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

  def wait_until_enabled(selector)
    wait_until(10) { first("#{selector}:not([disabled='disabled'])") }
  end

  def select2_select(value, options)
    id = options[:from]
    options[:from] = "#s2id_#{id}"
    targetted_select2(value, options)
  end

  # Support having different texts to search for and to click in the select2
  # field.
  #
  # This overrides the method in Spree.
  def targetted_select2_search(value, options)
    page.execute_script %{$('#{options[:from]}').select2('open')}
    page.execute_script "$('#{options[:dropdown_css]} input.select2-input').val('#{value}').trigger('keyup-change');"
    select_select2_result(options[:select_text] || value)
  end

  def multi_select2_select(value, options)
    find("#s2id_#{options[:from]}").find('ul li.select2-search-field').click
    select_select2_result(value)
  end

  def open_select2(selector)
    page.execute_script "jQuery('#{selector}').select2('open');"
  end

  def close_select2(selector)
    page.execute_script "jQuery('#{selector}').select2('close');"
  end

  def select2_search_async(value, options)
    id = find_label_by_text(options[:from])
    options[:from] = "#s2id_#{id}"
    targetted_select2_search_async(value, options)
  end

  def targetted_select2_search_async(value, options)
    page.execute_script %{$('#{options[:from]}').select2('open')}
    page.execute_script "$('#{options[:dropdown_css]} input.select2-input').val('#{value}').trigger('keyup-change');"
    select_select2_result_async(value)
  end

  def select_select2_result_async(value)
    while page.has_selector? "div.select2-searching"
      return if page.has_selector? "div.select2-no-results"

      sleep 0.2
    end
    page.execute_script(%{$("div.select2-result-label:contains('#{value}')").mouseup()})
  end

  def accept_js_alert
    page.driver.browser.switch_to.alert.accept
  end

  def angular_http_requests_finished(controller = nil)
    page.evaluate_script("#{angular_scope(controller)}.injector().get('$http').pendingRequests.length == 0")
  end

  def request_monitor_finished(controller = nil)
    page.evaluate_script("#{angular_scope(controller)}.scope().RequestMonitor.loading == false")
  end

  private

  # Takes an optional angular controller name eg: "LineItemsCtrl",
  # otherwise finds the first object in the DOM with an angular scope
  def angular_scope(controller = nil)
    element = controller ? "[ng-controller=#{controller}]" : '.ng-scope'
    "angular.element(document.querySelector('#{element}'))"
  end

  def wait_for_ajax
    wait_until { page.evaluate_script("$.active") == 0 }
  end
end
