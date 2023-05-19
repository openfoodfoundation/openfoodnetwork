# frozen_string_literal: true

RSpec::Matchers.define :have_tom_select do |selector, options = {}|
  #       http://www.rubydoc.info/github/jnicklas/capybara/Capybara/Node/Matchers#has_select%3F-instance_method

  match do |node|
    @selector, @options, @node = selector, options, node

    results = []

    results << node.has_selector?(selector)

    if results.all? && (options.key? :selected)
      results << selected_option_is?(options[:selected])
    end

    if results.all?
      results << all_options_present?(options[:with_options]) if options.key? :with_options
      results << exact_options_present?(options[:options]) if options.key? :options
      if options.key? :without_options
        results << all_options_absent?(options[:without_options])
      end
    end

    results.all?
  end

  failure_message do |_actual|
    message  = "expected to find Tom Select #{@selector}"
    message += " with #{@options.inspect}" if @options.any?
    message
  end

  match_when_negated do |node|
    @selector, @options, @node = selector, options, node

    results = []

    results << node.has_no_selector?(selector, wait: 1)

    if results.none? && (options.key? :with_options)
      results << all_options_absent(selector, options[:with_options])
    end

    if (options.keys & %i(selected options without_options)).any?
      raise "Not yet implemented"
    end

    results.any?
  end

  failure_message_when_negated do |_actual|
    message  = "expected not to find select2 ##{@id}"
    message += " with #{@options.inspect}" if @options.any?
    message
  end

  private

  def all_options_absent?(options)
    with_tom_select_open do
      @tom_select_wrapper = tom_select_wrapper
      options.all? do |option|
        @tom_select_wrapper.has_no_selector? "div[role=option]", text: option
      end
    end
  end

  def all_options_present?(options)
    with_tom_select_open do
      options.all? do |option|
        @node.has_selector? "div[role=option]", text: option
      end
    end
  end

  def exact_options_present?(options)
    with_tom_select_open do
      @node.all("div[role]=option").map(&:text) == options
    end
  end

  def selected_option_is?(text)
    within tom_select_wrapper do
      find("div.ts-control div.item").text == text
    end
  end

  def tom_select_wrapper
    find(@selector).sibling(".ts-wrapper")
  end

  def with_tom_select_open
    find(@selector).click # open
    r = yield
    find(@selector).click # close
    r
  end
end
