require 'ri_cal'

class EventCalendar
  attr_accessor :calendars
  attr_accessor :filenames # decorator?
  # also decoreate event for access to calendar?

  def initialize filename
    @calendars = []
    @filenames = []
    if filename.class == Array
      filename.each {|file| read_file file}
    else
      read_file filename
    end
  end

  def read_file filename
    @calendars << File.open(filename, 'r') do |file|
      RiCal.parse file
    end.flatten
    # attention if more than one calendar in file!
    @filenames << filename
    @calendars.flatten!
  end

  # Catches only certain events
  def singular_events_for_month year, month
    @calendar.map do |calendar|
      calendar.events.select { |event|
        event_between? event, dtmonth_start(year, month), dtmonth_end(year, month)
      }
    end.flatten
  end

  def events_for_date date
    @calendars.map do |calendar|
      calendar .events.select { |event|
        event_includes? event, date
      }
    end.flatten
  end

  # Best optimization potential
  def events_in start_date, end_date
    events = []
    (start_date .. end_date).each do |day|
      events << find_events(day)
    end
    events.flatten
  end

  def find_events date
    @calendars.map do |calendar|
      calendar.events.select { |event|
        event.dtstart.to_date == date || event.dtend.to_date == date ||!event.occurrences(:overlapping => [date, date +1]).empty?
      }
    end.flatten
  end

  def filename_of calendar
    @filenames[@calendars.index calendar]
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


