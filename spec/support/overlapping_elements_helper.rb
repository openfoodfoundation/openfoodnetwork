# frozen_string_literal: true

def dismiss_warning
  # Click dismiss on distributor warning
  click_button 'Dismiss'
end

def trigger_click(id, text)
  # replace node buy the elements node, for example
  page.find(id, text).trigger("click")
end
