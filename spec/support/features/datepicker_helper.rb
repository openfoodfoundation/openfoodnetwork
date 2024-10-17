# frozen_string_literal: true

module Features
  module DatepickerHelper
    def choose_today_from_datepicker
      within(".flatpickr-calendar.open") do
        find("button", text: "Today").click
      end
    end

    def select_dates_from_daterangepicker(from, to)
      # Once the datepicker is open,
      # it simply consist to select the 'from' date and then the 'to' date
      select_date_from_datepicker(from)
      select_date_from_datepicker(to)
    end

    def select_date_from_datepicker(date)
      within ".flatpickr-calendar.open" do
        # Unfortunately, flatpickr doesn't notice a change of year when we do
        #
        #     fill_in "Year", with: date.year
        #
        # A working alternative is:
        find(".cur-year").send_keys(date.year.to_s)
        select date.strftime("%B"), from: "Month"

        aria_date = date.strftime("%B %-d, %Y")
        find("[aria-label='#{aria_date}']").click
      end
    end

    def select_datetime_from_datepicker(datetime)
      ## First of all select date
      select_date_from_datepicker(datetime)
      # Then select time
      find(".flatpickr-calendar.open .flatpickr-hour").set datetime.strftime("%H").to_s.strip
      find(".flatpickr-calendar.open .flatpickr-minute").set datetime.strftime("%M").to_s.strip
    end

    def pick_datetime(calendar_selector, datetime_selector)
      find(calendar_selector).click
      select_datetime_from_datepicker datetime_selector
      find("body").send_keys(:escape)
    end
  end
end
