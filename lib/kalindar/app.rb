require 'time'
require 'json'
require 'securerandom'
require 'sinatra/base'
require 'slim'
require 'i18n'
require 'i18n/backend/fallbacks'
require 'listen'

# Read in calendar files, fill global cal var.
def cals
  EventCalendar.new($conf['calendar_files'])
end


# Sinatra App for Kalindar, show ics files.
class KalindarApp < Sinatra::Base
  $conf = JSON.load(File.new('config.json'))

  $cal = cals

  configure do
    I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
    I18n.load_path = Dir[File.join(settings.root, 'locales', '*.yml')]
    I18n.backend.load_translations
    I18n.default_locale = $conf['locale'].to_sym

    # Watch for calendar file changes.
    [*$conf['calendar_files']].each do |file|
      path = Pathname.new(file).realpath
      dir  = path.dirname.to_s
      base = path.basename.to_s
      listener = Listen.to(dir, only: /#{base}/) { $cal = cals }
      listener.start
    end
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

  # Add empty list for each day in date to date + number_days,
  # if no value set for given key
  def register_days hash, date, number_days
    (date.to_date .. (date.to_date + number_days)).each do |day|
      hash[day] ||= []
    end
    hash
  end

  get '/' do
    redirect '/events'
  end

  get '/events/:year/:month' do
    # Events from start time to 31 days later
    date = Date.new(params[:year].to_i, params[:month].to_i, 1)

    @events = $cal.events_in(date, date + 30)

    register_days @events, date, 30

    slim :event_list
  end

  get '/events' do
    # Events from today to in 30 days
    @events = $cal.events_in(Date.today, Date.today + 30)

    register_days @events, Date.today, 30

    slim :event_list
  end

  get '/events/twoday' do
    # events from today to in 30 days
    @events[day] = $cal.events_in Date.today, Date.today + 2
    
    #@events = @events.values.flatten.sort_by {|e| e.start_time}
    @today = Date.today
    @tomorrow = @today + 1

    slim :twoday_list
  end

  # Add new event, save ics file.
  put '/event' do
    errors = EventParamHelper.check_params params
    if !errors.empty?
      slim :new_event, :locals => {'start_date' => Date.parse(params[:start_day])}
    end
    begin
      event = Kalindar::Event.create_from_params params
    rescue Exception => e
      puts e.inspect
      puts e.backtrace
      return 502, "Eingabefehler"
    end

    $cal.calendars.first.events << event
    $cal.calendars.first.write_back!

    if request.xhr?
      # Events from today to in 30 days
      date = Date.today
      @events = $cal.events_in date, date + 30

      register_days @events, date, 30

      slim :event_list, :layout => false
    else
      redirect '/'
    end
  end

  # Show new event template.
  get '/event/new/:day' do
    # Aim is to get a new event in every case
    #@event = Event.create_from_params params
    @event = Kalindar::Event.new(RiCal::Component::Event.new($cal.calendars.first))
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

    # TODO: Make sure this is not an recuring event or in a not modifiable calendar.

    # validate_params
    if params[:submitbutton] == 'cancel'
      redirect '/'
    end
    puts params
    event = $cal.find_by_uid(params[:uuid])
    event.update params
    $cal.calendars.first.write_back!
    redirect '/'
  end

  post '/events/full' do
    params[:calendars]
    # events from today to in 30 days
    date = Date.today
    @events = $cal.events_in date .. date + 30

    register_days @events, date, 30

    slim :event_list
  end
end
