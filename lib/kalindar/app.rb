require 'sinatra/base'
require 'haml'
require 'time'
require 'json'

class KalindarApp < Sinatra::Base
  $conf = JSON.load(File.new('config.json'))
  $cal = EventCalendar.new($conf['calendar_file'])

  # Will use http-verb PUT
  enable :method_override

  get '/' do
    redirect '/events'
  end

  get '/events' do
    @events = {}
    # events from today to in 30 days
    (DateTime.now .. DateTime.now + 30).each do |day|
      #@events[d] = $cal.events_for(d)
      @events[day] = $cal.find_events day.to_date
      puts "#{day}: #{($cal.find_events day).length}"
    end
    haml :event_list
  end

  put '/event' do
    # alternatively RiCal.Event ?
    event = RiCal::Component::Event.new($cal.calendars.first)
    event.dtstart = Date.parse(params['start'])
    event.dtend = Date.parse(params['end'])
    event.summary = params['summary']
    $cal.calendars.first.events << event
    io = File.open($cal.filename_of($cal.calendars.first), 'w')
    $cal.calendars.first.export_to io
    io.close
    "save"
  end


  get '/event/new/:day' do
    haml :new_event
  end
end
