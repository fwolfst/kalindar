require 'ri_cal'
require 'kalindar/calendar'

# Public facing methods should return Event Decorators,
# private methods can return "raw" RiCal::Component::Event s.
class EventCalendar
  attr_accessor :calendars

  # Given filename or array of filenames, initialize the calendar.
  def initialize filename
    @calendars = []
    if filename.class == Array
      filename.each {|file| read_file file, true}
    else
      read_file filename, true
    end
  end

  # Opens calendar
  # param: create if true, create empty calendar file if not existant.
  def read_file filename, create
    if create && !File.exist?(filename)
      File.open(filename, 'w') do |file|
        (RiCal::Component::Calendar.new).export_to file
      end
    end
    @calendars << File.open(filename, 'r') do |file|
      RiCal.parse file
    end.flatten.map do |calendar|
      c = Calendar.new calendar
      c.filename = filename
      c
    end
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
    events = @calendars.map &:events
    events.select {|event| event_includes? event, date}.flatten
    events.map {|event|
      Event.new event
    }
  end

  # Nother optimization potential
  def events_per_day start_date, end_date
    map = {}
    (start_date .. end_date).each do |day|
      (map[day] ||= []) << find_events(day)
    end
    map
  end

  # Best optimization potential
  def events_in start_date, end_date
    events = []
    (start_date .. end_date).each do |day|
      events << find_events(day)
    end
    events.flatten
  end

  # Find (non-recuring) events that begin, end or cover the given day.
  def find_events date
    #events = @calendars.map &:events
    @calendars.map do |calendar|
      calendar.events.select { |event|
        # If end-date is a Date (vs DateTime) let it be
        # All day/multiple day events
        if event.dtstart.class == Date && event.dtend.class == Date
          event.dtstart.to_date == date
        else
          event.dtstart.to_date == date || event.dtend.to_date == date
          # occurrences need to be re-enabled
          #||!event.occurrences(:overlapping => [date, date +1]).empty?
        end
      }
    end.flatten.map do |event|
      Event.new event
    end
    # check flat_map enumerable method
  end

  def find_by_uid uuid
    # we want to pick only the first! whats the method? detect is one, find another
    @calendars.map(&:events).flatten.each do |event|
      return Event.new(event) if event.uid == uuid
    end
    nil
  end

  private

  def dtmonth_start year, month
    Icalendar::Values::Date.new('20101001')#"#{year}%02d%02d"%[month,01])
  end

  def dtmonth_end year, month
    #puts "last date for #{year} - #{month}"
    last_day = Date.civil(year, month, -1)
    Icalendar::Values::Date.new('20120102')#"#{year}#{month}#{last_day}")
  end

  def date_between? date, start_date, end_date
    #puts "d #{date}  st #{start_date} e #{end_date}"
    date > start_date && date < end_date
  end

  def event_between? event, start_date, end_date
    event.dtstart.class == event.dtend.class && event.dtstart.class ==  Icalendar::Values::DateTime && (date_between?(event.dtstart, start_date, end_date) || date_between?(event.dtend, start_date, end_date))
  end

  def event_includes? event, date
    incl = event.dtstart.class == event.dtend.class && event.dtstart.class ==  Icalendar::Values::DateTime && (date_between?(date, event.dtstart, event.dtend))
    incl
  end
end


