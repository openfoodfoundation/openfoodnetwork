# frozen_string_literal: true

module Features
  module DatepickerHelper
    def choose_today_from_datepicker
      within(".ui-datepicker-calendar") do
        find(".ui-datepicker-today").click
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
      find('#ui-datepicker-div .ui-datepicker-header .ui-datepicker-prev').click
    end

    def navigate_datepicker_to_next_month
      find('#ui-datepicker-div .ui-datepicker-header .ui-datepicker-next').click
    end

    def datepicker_month_and_year
      find("#ui-datepicker-div .ui-datepicker-title").text
    end
  end
end
