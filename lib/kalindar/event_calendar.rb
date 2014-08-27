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

  # start_date and end_date are inclusive,
  # start_date can be Timespan, too
  def events_in start_date, end_date=nil
    if end_date.nil? && !start_date.is_a?(Timespan)
      timespan = Timespan.day_end start_date
      end_date = timespan.finish
      start_date = timespan.start
    end
    if start_date.is_a? Timespan
      timespan = start_date
      end_date = start_date.finish
      start_date = start_date.start
    end

    # All overlapping occurences.
    occurrences = events.map do |e|
      e.occurrences(:overlapping => [start_date, end_date])
    end

    # Collect occurences by date.
    hash = occurrences.inject({}) do |hsh, o|
      o.each do |oc|
        event = Kalindar::Event.new(oc)
        (oc.dtstart.to_date .. oc.dtend.to_date).each do |day|
          # Strip timerange and exclude one-and-whole-day events (they "end" next day).
          if day >= start_date && day <= end_date && !(oc.dtstart != oc.dtend && oc.dtend.class == Date && oc.dtend == day)
            (hsh[day] ||= []) << event
          end
        end
      end
      hsh
    end
    hash
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
end
