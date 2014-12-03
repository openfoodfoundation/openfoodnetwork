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
    def use_short_wait
      around { |example| Capybara.using_wait_time(2) { example.run } }
    end
  end


  def current_path_should_be path
    current_path = URI.parse(current_url).path
    current_path.should == path
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


  def should_have_failed
    page.status_code.should == 200
    errors.count.should > 0
  end

  def successful?
    page.status_code.should == 200
    errors.count.should == 0
    flash_message.should include 'successful'
  end

  def updated_field(field, value)
    wait_for_ajax
    yield(field, value)
  rescue Capybara::TimeoutError
    flunk "Expected #{field} to update to #{value}."
  end

  def updated_css(css)
    wait_for_ajax
    yield(css)
  rescue Capybara::TimeoutError
    flunk "Expected updated css: #{css}."
  end

  def user_nav
    find('div.user/div.name').text
  end

  def flash_message
    find('.flash').text.strip
  end

  def errors
    all('.error')
  end

  def property_name
    find('.property-name').text
  end

  def error_messages
    errors.map(&:text)
  end

  def handle_js_confirm(accept=true, debug=false)
    page.evaluate_script "window.confirm = function(msg) { return #{!!accept }; }"
    yield
  end

  def handle_webdriver_random_failure(retry_times = 3)
    begin
      yield
    rescue Selenium::WebDriver::Error::InvalidSelectorError => e
      e.message =~ /nsIDOMXPathEvaluator.createNSResolver/ ? (retry if (retry_times -= 1 ) > 0) : raise
    end
  end

  def click_dialog_button(button_content)
    page.find(:xpath, "//div[@class=\"ui-dialog-buttonset\"]//span[contains(text(),\"#{button_content}\")]").click
  end

  def visit_delete(url)
    response = Capybara.current_session.driver.delete url
    click_link 'redirected' if response.status == 302
  end

  def trigger_manual_event(field_selector, event = 'change')
    page.execute_script("$('#{field_selector}').trigger('#{event}');")
  end

  def dirty_form_dialog
    DirtyFormDialog.new(page)
  end

  # http://www.elabs.se/blog/53-why-wait_until-was-removed-from-capybara
  # Do not use this without good reason. Capybara's built-in waiting is very effective.
  def wait_until
    require "timeout"
    Timeout.timeout(Capybara.default_wait_time) do
      sleep(0.1) until value = yield
      value
    end
  end

  def select2_select(value, options)
    id = options[:from]
    options[:from] = "#s2id_#{id}"
    targetted_select2(value, options)
  end

  # Deprecated: Use have_select2 instead (spec/support/matchers/select2_matchers.rb)
  def have_select2_option(value, options)
    container = options[:dropdown_css] || ".select2-with-searchbox"
    page.execute_script %Q{$('#{options[:from]}').select2('open')}
    page.execute_script "$('#{container} input.select2-input').val('#{value}').trigger('keyup-change');"
    sleep 1
    have_selector "div.select2-result-label", text: value
  end


  private
  def wait_for_ajax
    wait_until { page.evaluate_script("$.active") == 0 }
  end
end

