Spree::Money.class_eval do

  # return the currency symbol (on its own) for the current default currency
  def self.currency_symbol
    Money.new(0, Spree::Config[:currency]).symbol
  end

  def rounded
    @options[:no_cents] = true if @money.dollars % 1 == 0
    to_s
  end

  def to_html(options = { :html => true })
    output = @money.format(@options.merge(options))
    if options[:html]
      # 1) prevent blank, breaking spaces
      # 2) prevent escaping of HTML character entities
      output = output.sub(" ", "&nbsp;").html_safe
    end
    output
  end

  def format(options={})
    @money.format(@options.merge!(options))
  end
end
