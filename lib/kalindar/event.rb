require 'delegate'

# Delegator with some handy shortcuts
class Event < SimpleDelegator
  # Time it starts at day, or '...'
  def start_time_f day
    #puts "start #{start_time} : #{start_time.class} #{start_time.to_date} #{day}"
    if dtstart.class == Date
      # whole day
      ""
    elsif start_time.to_date == day.to_date
      start_time.strftime('%H:%M')
    else
      "..."
    end
  end

  # Time it finishes at day, or '...'
  def finish_time_f day
    if dtend.class == Date
      # whole day
      ""
    elsif finish_time.to_date == day.to_date
      finish_time.strftime('%H:%M')
    else
      return "..."
    end
  end

  # Time it finishes and or starts at day, or '...'
  def time_f day
    start = start_time_f day
    finish = finish_time_f day
    if start == finish && start == ""
      # whole day
      ""
    elsif start == finish && start == "..."
      "..."
    else
      "#{start_time_f day} - #{finish_time_f day}"
    end
  end

  # Date and time from and to
  def from_to_f
    return "#{dtstart.to_datetime.strftime("%d.%m. %H:%M")} - #{dtend.to_datetime.strftime("%d.%m. %H:%M")}"
  end

  # Create DateTime from yyyymmdd + h + m .
  def self.start_time_from_params params
    start_day = Date.parse(params['start_day'])
    if !params[:start_time]
      return start_day
    end

    hour, minute = params[:start_time].match(/(\d\d):(\d\d)/)[1,2]
    start_time = DateTime.new(start_day.year,
      start_day.month, start_day.day, hour.to_i, minute.to_i)
  end

  def self.start_date_from params
    Date.parse(params['start_day'])
  end


  def update params
    begin
      hour, minute = params['start_time'].match(/(\d\d):(\d\d)/)[1,2]
      start_day = Date.parse(params['start_day'])
      start_time = DateTime.new(start_day.year,
        start_day.month, start_day.day, hour.to_i, minute.to_i)
      self.dtstart = start_time
      minutes = EventParamHelper.duration params['duration']
      self.dtend = start_time + Rational(minutes, 1440)
    rescue => e
      STDERR.puts "event#update params: problems with (up)date #{e.message}"
    end
    
    self.summary     = params['summary']     if params['summary']
    self.description = params['description'] if params['description']
    self.location    = params['location']    if params['location']
  end

  # Create a new event from params as given by new_event form of kalindar.
  # this should eventually go somewhere else, but its better here than in app already.
  def self.create_from_params params
    event = RiCal::Component::Event.new($cal.calendars.first)
    event.uid = SecureRandom.uuid
    if params['summary']
      event.summary = params['summary']
    end
    if params['description']
      event.description = params['description']
    end
    if params['location']
      event.location = params['location']
    end

    # Access should be made failsafe.
    start_time = start_time_from_params(params)
    event.dtstart = start_time
    minutes = EventParamHelper.duration params['duration']
    event.dtend = start_time + Rational(minutes, 1440)
    Event.new event
  end

  private
end

module EventParamHelper
  
  # minutes for abbrevations
  @@duration_param = {
    '15m' => 15,
    '30m' => 30,
    '60m' => 60,
    '90m' => 90,
    '120m' => 120,
    '1d'  => 24 * 60,
    '2d'  => 24 * 2 * 60,
    '5d'  => 24 * 5 * 60,
    '1w'  => 24 * 7 * 60
  }
  def self.duration duration_p
    # throw
    @@duration_param[duration_p]
  end

  def self.check_params params
    errors = {}
    if not(params[:start_time] =~ /\d\d:\d\d/)
      errors[:start_time] = ''
    end
    if not(duration params[:duration])
      errors[:duration] = ''
    end
    errors
  end
end
