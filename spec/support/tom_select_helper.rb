# frozen_string_literal: true

module TomSelectHelper
  def select_tom_select(value, from:)
    container = find(:id, from)

    within(container) do
      find('.ts-control').send_keys(value)
    end

    all('.ts-dropdown .ts-dropdown-content .option', text: /#{Regexp.quote(value)}/i)[0].click
  end
end
