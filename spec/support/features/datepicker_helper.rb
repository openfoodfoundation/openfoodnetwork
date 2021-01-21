# frozen_string_literal: true

module Features
  module DatepickerHelper
    def choose_today_from_datepicker
      within(".flatpickr-calendar.open") do
        find('.shortcut-buttons-flatpickr-button').click
      end
    end

    def navigate_datepicker_to_month(date, reference_date = Time.zone.today)
      month_and_year = date.strftime("%B %Y")

      until datepicker_month_and_year == month_and_year.upcase
        if date < reference_date
          navigate_datepicker_to_previous_month
        elsif date > reference_date
          navigate_datepicker_to_next_month
        end
      end
    end

    def navigate_datepicker_to_previous_month
      find('.flatpickr-calendar.open .flatpickr-months .flatpickr-prev-month').click
    end

    def navigate_datepicker_to_next_month
      find('.flatpickr-calendar.open .flatpickr-months .flatpickr-next-month').click
    end

    def datepicker_month_and_year
      find(".flatpickr-calendar.open .flatpickr-current-month").text
    end
  end
end
