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
    def use_short_wait(seconds=2)
      around { |example| Capybara.using_wait_time(seconds) { example.run } }
    end
  end

  def have_input(name, opts={})
    selector  = "[name='#{name}']"
    selector += "[placeholder='#{opts[:placeholder]}']" if opts.key? :placeholder

    element = page.all(selector).first
    element.value.should == opts[:with] if element && opts.key?(:with)

    have_selector selector
  end

  def fill_in_fields(field_values)
    field_values.each do |key, value|
      begin
        fill_in key, :with => value
      rescue Capybara::ElementNotFound
        find_field(key).select(value)
      end
    end
  end

  def select_by_value(value, options={})
    from = options.delete :from
    page.find_by_id(from).find("option[value='#{value}']").select_option
  end

  def flash_message
    find('.flash', visible: false).text.strip
  end

  def handle_js_confirm(accept=true)
    page.execute_script "window.confirm = function(msg) { return #{!!accept }; }"
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
  def script_content(opts={})
    elems = page.all('script', visible: false)

    elems = elems.to_a.select { |e| e.text(:all).include? opts[:with] }  if opts[:with]

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
  def wait_until(secs=nil)
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

  def perform_and_ensure(action, *args, assertion)
    # Buttons/Links/Checkboxes can be unresponsive for a while
    # so keep clicking them until assertion is satified
    using_wait_time 0.5 do
      10.times do
        send(action, *args)
        return if assertion.call
      end
      # Only make it here if we have tried 10 times
      expect(assertion.call).to be true
    end
  end

  private

  def wait_for_ajax
    wait_until { page.evaluate_script("$.active") == 0 }
  end
end
