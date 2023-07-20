# frozen_string_literal: true

module Features
  module DatepickerHelper
    def choose_today_from_datepicker
      within(".flatpickr-calendar.open") do
        find("button", text: "TODAY").click
      end
    end

    def select_dates_from_daterangepicker(from, to)
      # Once the datepicker is open,
      # it simply consist to select the 'from' date and then the 'to' date
      select_date_from_datepicker(from)
      select_date_from_datepicker(to, from)
    end

    def select_date_from_datepicker(date, reference_date = Time.zone.today)
      navigate_datepicker_to_month(date, reference_date)
      find('.flatpickr-calendar.open .flatpickr-days .flatpickr-day:not(.prevMonthDay)',
           text: date.strftime("%e").to_s.strip, exact_text: true, match: :first).click
    end

    def select_datetime_from_datepicker(datetime)
      ## First of all select date
      select_date_from_datepicker(datetime)
      # Then select time
      find(".flatpickr-calendar.open .flatpickr-hour").set datetime.strftime("%H").to_s.strip
      find(".flatpickr-calendar.open .flatpickr-minute").set datetime.strftime("%M").to_s.strip
    end

    def navigate_datepicker_to_month(date, reference_date)
      month_and_year = date.strftime("%-m %Y")

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
      month = find(".flatpickr-calendar.open .flatpickr-current-month " \
                   "select.flatpickr-monthDropdown-months").value.to_i + 1
      year = find(".flatpickr-calendar.open .flatpickr-current-month " \
                  ".numInputWrapper .cur-year").value
      month.to_s + " " + year.to_s
    end

    def pick_datetime(calendar_selector, datetime_selector)
      find(calendar_selector).click
      select_datetime_from_datepicker datetime_selector
      find("body").send_keys(:escape)
    end
  end
end
