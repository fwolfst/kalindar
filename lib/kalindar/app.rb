require 'time'
require 'json'
require 'securerandom'
require 'sinatra/base'
require 'slim'
require 'i18n'
require 'i18n/backend/fallbacks'

class KalindarApp < Sinatra::Base
  $conf = JSON.load(File.new('config.json'))
  $cal = EventCalendar.new($conf['calendar_files'])

  configure do
    I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
    I18n.load_path = Dir[File.join(settings.root, 'locales', '*.yml')]
    I18n.backend.load_translations
    I18n.default_locale = $conf['locale'].to_sym
  end

  # Will use http-verb PUT
  enable :method_override

  # We like pretty html indentation
  set :slim, :pretty => true

  helpers do
    def li_day_class day
      return "sunday" if day.sunday?
      return "saturday" if day.saturday?
      "day"
    end
    def t(*args)
      I18n.t(*args)
    end
    def l(*args)
      I18n.l(*args)
    end
  end

  get '/' do
    redirect '/events'
  end

  get '/events' do
    @events = {}
    # events from today to in 30 days
    (DateTime.now .. DateTime.now + 30).each do |day|
      #@events[d] = $cal.events_for(d)
      @events[day] = $cal.find_events day.to_date
    end
    slim :event_list
  end

  # Create DateTime from yyyymmdd + h + m .
  def start_time_from_params params
    hour = params['start_time'][/\d\d/].to_i
    minute = params['start_time'][/:\d\d/][1,2].to_i
    start_day = Date.parse(params['start_day'])
    start_time = DateTime.new(start_day.year,
      start_day.month, start_day.day, hour, minute)
  end

  # Adds minutes to start_time.
  def end_time_from_params params, start_time
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
    start_time + Rational(minutes, 1440) 
  end

  # Add event, save ics file.
  put '/event' do
    event = RiCal::Component::Event.new($cal.calendars.first)
    event.uid = SecureRandom.uuid
    start_time = start_time_from_params params
    event.dtstart = start_time
    event.dtend = end_time_from_params params, start_time
    event.summary = params['summary']
    event.description = params['description']
    event.location = params['location']

    # Motivate Calendar Delegate
    $cal.calendars.first.events << event
    $cal.calendars.first.write_back!

    redirect back
  end

  get '/event/new/:day' do
    slim :new_event, :locals => {'start_date' => nil}
  end
end
