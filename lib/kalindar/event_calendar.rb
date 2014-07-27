require 'icalendar'

class EventCalendar
  attr_accessor :calendar

  def initialize filename
    read_file filename
  end

  def read_file filename
    @calendar = Icalendar.parse(File.read filename).first
  end

  # Catches only certain events
  def singular_events_for_month year, month
    @calendar.events.select { |event|
      event_between? event, dtmonth_start(year, month), dtmonth_end(year, month)
    }
  end

  def events_for date
    @calendar.events.select { |event|
      event_includes? event, date
    }
  end

  def find_events date
    @calendar.events.select { |event|
      event.dtstart.to_date == date || event.dtend.to_date == date
    }
  end

  private

  def dtmonth_start year, month
    Icalendar::Values::Date.new('20101001')#"#{year}%02d%02d"%[month,01])
  end

  def dtmonth_end year, month
    puts "last date for #{year} - #{month}"
    last_day = Date.civil(year, month, -1)
    Icalendar::Values::Date.new('20120102')#"#{year}#{month}#{last_day}")
  end

  def date_between? date, start_date, end_date
    puts "d #{date}  st #{start_date} e #{end_date}"
    date > start_date && date < end_date
  end

  def event_between? event, start_date, end_date
    event.dtstart.class == event.dtend.class && event.dtstart.class ==  Icalendar::Values::DateTime && (date_between?(event.dtstart, start_date, end_date) || date_between?(event.dtend, start_date, end_date))
  end

  def event_includes? event, date
    event.dtstart.class == event.dtend.class && event.dtstart.class ==  Icalendar::Values::DateTime && (date_between?(date, event.dtstart, event.dtend))
  end
end


