require 'time'
require 'json'
require 'securerandom'
require 'sinatra/base'
require 'slim'
require 'i18n'
require 'i18n/backend/fallbacks'

# Sinatra App for Kalindar, show ics files.
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

  # Allow inclusion in iframe.
  set :protection, :except => :frame_options

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

  get '/events/:year/:month' do
    @events = {}
    # Events from start time to 31 days later
    date = Date.new(params[:year].to_i, params[:month].to_i, 1)
    (date .. date + 30).each do |day|
      #@events[d] = $cal.events_for(d)
      @events[day] = $cal.find_events day.to_date
    end
    slim :event_list
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

  get '/events/twoday' do
    @events = {}
    # events from today to in 30 days
    (DateTime.now .. DateTime.now + 30).each do |day|
      #@events[d] = $cal.events_for(d)
      @events[day] = $cal.find_events day.to_date
    end
    @events = @events.values.flatten.sort_by {|e| e.start_time}
    slim :twoday_list
  end

  # Add new event, save ics file.
  put '/event' do
    errors = EventParamHelper.check_params params
    if !errors.empty?
      slim :new_event, :locals => {'start_date' => Date.parse(params[:start_day])}
    end
    begin
      event = Event.create_from_params params
    rescue
      return 502, "Eingabefehler"
    end

    $cal.calendars.first.events << event
    $cal.calendars.first.write_back!

    if request.xhr?
      @events = {}
      # Events from today to in 30 days
      (DateTime.now .. DateTime.now + 30).each do |day|
        @events[day] = $cal.find_events day.to_date
      end
      slim :event_list, :layout => false
    else
      redirect '/'
    end
  end

  # Show new event template.
  get '/event/new/:day' do
    # Aim is to get a new event in every case
    #@event = Event.create_from_params params
    @event = Event.new(RiCal::Component::Event.new($cal.calendars.first))
    @event.dtstart = Date.parse(params[:day])
    slim :new_event, :locals => {'start_date' => Date.parse(params[:day])}
  end

  # Yet empty route.
  get '/event/delete/:uuid' do
    redirect back
  end

  # Show edit view.
  get '/event/edit/:uuid' do
    event = $cal.find_by_uid params[:uuid]
    if event.nil?
      redirect back
    else
      slim :edit_event, :locals => {'event' => event}
    end
  end

  # Edit/save an event.
  put '/event/edit/:uuid' do
    # validate_params
    puts params
    event = $cal.find_by_uid(params[:uuid])
    event.update params
    $cal.calendars.first.write_back!
    redirect '/'
  end
end
