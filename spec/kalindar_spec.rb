require 'spec_helper'
require 'ri_cal'

describe Kalindar do
  it 'has a version number' do
    expect(Kalindar::VERSION).not_to be nil
  end
end

describe EventCalendar do
  subject { EventCalendar.new 'spec/testcal.ics' }

  describe "#new" do
    it 'parses an ics file' do
      cal = EventCalendar.new 'spec/testcal.ics'
    end
    it 'initializes alternatively with a list of ics files' do
      cal = EventCalendar.new ['spec/testcal.ics', 'spec/testcal2.ics']
      expect(cal.calendars.length).to eql 2
    end
  end

  it 'exposes filename of parsed calendar' do
    cal = EventCalendar.new ['spec/testcal.ics', 'spec/testcal2.ics']
    expect(cal.calendars.first.filename).to eql 'spec/testcal.ics'
  end


  endjuly = Timespan.new(Date.new(2014, 07, 27), Date.new(2014, 07, 28)).freeze

  latejuly = Date.new(2014, 07, 27).freeze

  describe "#events_in" do
    it 'finds recurring events' do
      events = subject.events_in (Date.new(2014, 07, 28))
      event_names = events.values.flatten.map(&:summary)
      expect(event_names.include? "daily").to eq true
    end
    it 'finds multiday events that cover the given date' do
      events = subject.events_in latejuly
      expect(events.values.flatten.map(&:summary).include? "multidays").to eq true
    end
    it 'handles whole day endtime correctly (ends next day)' do
      events = subject.events_in (Date.new(2014, 07, 28))
      event_names = events.values.flatten.map(&:summary)
      expect(event_names.include? "allday").to eq false
    end
    it 'finds events given date (like find_events_simple)' do
      events = subject.events_in latejuly
      event_names = events.values.flatten.map(&:summary)
      expect(event_names.include? "onehour").to eq true
      expect(event_names.include? "allday").to eq true
    end
    it 'finds normal recuring event.' do
      events = subject.events_in (Date.new(2014, 07, 27))
      expect(events.values.flatten.map(&:summary).include? "daily").to eq true
    end
    # multiday events should come up multiple times!
    it 'accesses events between two dates' do
      events = subject.events_in endjuly
      event_names = events.values.flatten.map(&:summary)
      expect(event_names).to eq ["allday", "onehour", "multidays", "daily", "multidays", "daily"]
    end
    it '#events_in by day' do
      events = subject.events_in endjuly
      # And they come in a hash
      expect(events.class).to eq({}.class)
    end
    it 'wraps in Event Delegate' do
      events = subject.events_in endjuly
      expect(events.values.flatten.collect{|e| e.is_a? Kalindar::Event}.length).to eq events.values.flatten.length
      expect(events.values.flatten[0].modifiable?).to eql true
      expect(events.values.flatten[0].calendar.class).to eql Calendar
    end
  end

  describe "#find_by_uid" do
    it 'finds by uuid' do
      event = subject.find_by_uid 'cb523dc2-eab8-49c9-a99f-ed69ac3b65d0'
      expect(event.summary).to eq 'allday'
    end
    it 'wraps in Event Delegate' do
      event = subject.find_by_uid 'cb523dc2-eab8-49c9-a99f-ed69ac3b65d0'
      expect(event.is_a? Kalindar::Event).to eq true
    end
  end
end

describe "Event" do
  subject(:allday_event) {}
  # This tests the calendar, not the event class
  subject(:events) {
    cal = EventCalendar.new 'spec/testcal.ics'
    cal.events_in(Date.new(2014, 8, 27), Date.new(2014, 8, 28)).values.first
  }
  subject(:allday_event) {
    cal = EventCalendar.new 'spec/testcal.ics'
    cal.find_by_uid("cb523dc2-eab8-49c9-a99f-ed69ac3b65d0")
  }
  subject(:multiday_event) {
    cal = EventCalendar.new 'spec/testcal.ics'
    cal.find_by_uid("4a129461-cd74-4b3a-a307-faa1e8846cc2")
  }
  subject(:daily_event) {
    cal = EventCalendar.new 'spec/testcal.ics'
    cal.find_by_uid("d7844d09-75d9-4a8b-a1de-453fe63d6415")
  }

  describe "#start_time_f" do
    it "returns the time if given day is start day" do
      expect(events[0].start_time_f Date.new(2014, 8, 27)).to eq "12:00"
      expect(events[0].start_time_f Date.new(2014, 8, 28)).to eq "..."
    end
  end

  describe "#modifiable?" do
    it 'makes non-recuring events modifiable' do
      expect(multiday_event.modifiable?).to eql false
    end
  end

  describe "#finish_time_f" do
    it "returns the time if given day is end day" do
      expect(events[0].finish_time_f Date.new(2014, 8, 27)).to eq "..."
      expect(events[0].finish_time_f Date.new(2014, 8, 28)).to eq "13:00"
    end
  end

  describe "#time_f" do
    it "returns the from to time for given day" do
      expect(allday_event.time_f Date.new(2014, 7, 27)).to eq ""
    end
    it "renders multiday in between with ... " do
      expect(multiday_event.time_f Date.new(2014, 7, 27)).to eq "..."
    end
  end

  describe "#from_to_f" do
    it "returns the from to time" do
      expect(events[0].from_to_f).to eq "27.08. 12:00 - 28.08. 13:00"
    end
  end

  describe "#update" do
    it "updates from params" do
      # should be fail safe, too
      cal = EventCalendar.new 'spec/testcal.ics'
      event = cal.find_by_uid("aea8d217-8025-4d9b-88e6-3df9e6abd33c")

      params = {'location' => 'a place', 'description' => 'exact description', 'summary'=> 'synopsis', 'duration' => '15m', 'start_day' => '20140808', 'start_time' => '10:10'}
      event.update params

      event_fetched = cal.find_by_uid("aea8d217-8025-4d9b-88e6-3df9e6abd33c")
      expect(event_fetched.location).to eql 'a place'
      expect(event_fetched.description).to eql 'exact description'
      expect(event_fetched.summary).to eql 'synopsis'
      expect(event_fetched.dtstart).to eq DateTime.new(2014, 8, 8, 10, 10)
      expect(event_fetched.dtend).to eq DateTime.new(2014, 8, 8, 10, 25)
    end
  end
end

describe Timespan do
  describe "#spans?" do
    it 'works with dates' do
      today = Date.today
      expect(Timespan.new(today, today + 4).spans? today + 3).to eql true
    end
  end
end
