require 'delegate'

# Delegator with some handy shortcuts
class Event < SimpleDelegator
  # Time it starts at day, or '...'
  def start_time_f day
    #puts "start #{start_time} : #{start_time.class} #{start_time.to_date} #{day}"
    return start_time.strftime('%H:%M') if start_time.to_date == day.to_date
    return "..."
  end

  # Time it finishes at day, or '...'
  def finish_time_f day
    return finish_time.strftime('%H:%M') if finish_time.to_date == day.to_date
    return "..."
  end

  # Time it finishes and or starts at day, or '...'
  def time_f day
    start = start_time_f day
    finish = finish_time_f day
    if start == finish && start == "..."
      "..."
    else
      "#{start_time_f day} - #{finish_time_f day}"
    end
  end

  # Date and time from and to
  def from_to_f
    return "#{dtstart.to_datetime.strftime("%d.%m. %H:%M")} - #{dtend.to_datetime.strftime("%d.%m. %H:%M")}"
  end

  # Create a new event from params as given by new_event form of kalindar.
  # this should eventually go somewhere else, but its better here than in app already.
  def self.create_from_params params
    event = RiCal::Component::Event.new($cal.calendars.first)
    event.uid = SecureRandom.uuid
    start_time = start_time_from_params params
    event.dtstart = start_time
    event.dtend = end_time_from_params params, start_time
    event.summary = params['summary']
    event.description = params['description']
    event.location = params['location']
    Event.new event
  end

  private

  # Create DateTime from yyyymmdd + h + m .
  def self.start_time_from_params params
    hour = params['start_time'][/\d\d/].to_i
    minute = params['start_time'][/:\d\d/][1,2].to_i
    start_day = Date.parse(params['start_day'])
    start_time = DateTime.new(start_day.year,
      start_day.month, start_day.day, hour, minute)
  end

  # Adds minutes to start_time.
  def self.end_time_from_params params, start_time
    minutes = case params['duration']
             when '15m' then 15
             when '30m' then 30
             when '60m' then 60
             when '90m' then 90
             when '120m' then 120
             when '1d' then 24 * 60
             when '2d' then 24 * 2 * 60
             when '5d' then 24 * 5 * 60
             when '1w' then 24 * 7 * 60
             end
    # alternatively, set the duration only, and hope ri_cal will do fine.
    start_time + Rational(minutes, 1440) 
  end

end
