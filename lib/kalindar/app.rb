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

  # Add event, save ics file.
  put '/event' do
    puts params
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

    # redirect back
    #redirect '/'

    if request.xhr?
      @events = {}
      # events from today to in 30 days
      (DateTime.now .. DateTime.now + 30).each do |day|
        #@events[d] = $cal.events_for(d)
        @events[day] = $cal.find_events day.to_date
      end
      slim :event_list, :layout => false
    else
      redirect '/'
    end
  end

  get '/event/new/:day' do
    slim :new_event, :locals => {'start_date' => nil}
  end

  get '/event/edit/:uuid' do
    slim :edit_event, :locals => {'event' => $cal.calendars.first.events[0]}
  end
end
