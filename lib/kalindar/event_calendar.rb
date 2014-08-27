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

  # Find events during date(s)/timespan.
  # start_date and end_date are inclusive,
  # start_date can be Timespan, too
  def events_in start_date, end_date=nil
    if end_date.nil? && !start_date.is_a?(Timespan)
      timespan = Timespan.day_end start_date
    end
    if start_date.is_a? Timespan
      timespan = start_date
    end
    if start_date && end_date
      timespan = Timespan.new start_date, end_date
    end

    events_in_time = @calendars.map.with_index do |calendar, idx|
      # Collect Kalindar::Events in that time
      events = calendar.events.map do |event|
        occurrences_in(event, timespan).map {|e| Kalindar::Event.new e }
      end.flatten

      # Set modification and calendar field.
      is_first = idx == 0
      events.each do |e|
        e.modifiable = is_first
        e.calendar = calendar
      end
      events
    end.flatten

    # Collect occurences by date.
    unfold_dates events_in_time, timespan
  end

  def find_by_uid uuid
    # we want to pick only the first! whats the method? detect is one, find another
    @calendars.map(&:events).flatten.each do |event|
      return Kalindar::Event.new(event) if event.uid == uuid
    end
    nil
  end

  def events
    @calendars.map(&:events).flatten
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

  # List occurrences in timespan
  def occurrences_in event, timespan
    event.occurrences(:overlapping => [timespan.start, timespan.finish])
  end

  # Make hash with one entry per day and event that lies in timespan
  def unfold_dates events, timespan
    events.inject({}) do |hash, event|
      (event.dtstart.to_date .. event.dtend.to_date).each do |day|
        if timespan.spans?(day) && !(event.dtstart != event.dtend && event.dtend.class == Date && event.dtend == day)
          (hash[day] ||= []) << event
        end
      end
      hash
    end
  end
end
