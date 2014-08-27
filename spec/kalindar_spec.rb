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

  describe "#find_events_simple" do
    it 'finds events given date' do
      events = subject.find_events (Date.new(2014, 07, 27))
      event_names = events.map(&:summary)
      expect(event_names.include? "onehour").to eq true
      expect(event_names.include? "allday").to eq true
    end
    it 'handles whole day endtime correctly (ends next day)' do
      events = subject.find_events (Date.new(2014, 07, 28))
      event_names = events.map(&:summary)
      expect(event_names.include? "allday").to eq false
    end
    it 'finds multiday events that cover the given date' do
      events = subject.find_events (Date.new(2014, 07, 27))
      expect(events.map(&:summary).include? "multidays").to eq true
    end
    it 'wraps events as Event delegates' do
      events = subject.find_events (Date.new(2014, 07, 27))
      events.each do |event|
        expect(event.is_a? Event).to eq true
      end
    end
  end

  it 'finds events that reocur' do
    events = subject.find_events (Date.new(2014, 07, 28))
    event_names = events.map(&:summary)
    expect(event_names.include? "daily").to eq true
  end

  describe "#events_in" do
    it 'accesses events between two dates' do
      events = subject.events_in(Date.new(2014, 07, 27), Date.new(2014, 07, 28))
      event_names = events.map(&:summary)
      expect(event_names).to eq ["allday", "onehour", "daily", "daily"]
    end
    it '#events_in by day' do
      events = subject.events_in(Date.new(2014, 7, 27), Date.new(2014, 7, 28))
      event_names = events.map(&:summary)
      expect(event_names).to eq ["allday", "onehour", "daily", "allday", "daily"]
      expect(event_names.class).to eq({}.class)
    end
    # multiday events!
    it 'wraps in Event Delegate' do
      events = subject.events_in(Date.new(2014, 7, 27), Date.new(2014, 7, 28))
      expect(events.collect{|e| e.is_a? Event}.length).to eq events.length
    end
  end

  describe "#find_by_uid" do
    it 'finds by uuid' do
      event = subject.find_by_uid 'cb523dc2-eab8-49c9-a99f-ed69ac3b65d0'
      expect(event.summary).to eq 'allday'
    end
    it 'wraps in Event Delegate' do
      event = subject.find_by_uid 'cb523dc2-eab8-49c9-a99f-ed69ac3b65d0'
      expect(event.is_a? Event).to eq true
    end
  end
end

describe "Event" do
  subject(:allday_event) {}
  subject(:events) {
    cal = EventCalendar.new 'spec/testcal.ics'
    cal.events_in(Date.new(2014, 8, 27), Date.new(2014, 8, 28))
  }
  subject(:allday_event) {
    cal = EventCalendar.new 'spec/testcal.ics'
    cal.find_by_uid("cb523dc2-eab8-49c9-a99f-ed69ac3b65d0")
  }
  subject(:multiday_event) {
    cal = EventCalendar.new 'spec/testcal.ics'
    cal.find_by_uid("4a129461-cd74-4b3a-a307-faa1e8846cc2")
  }

  describe "#start_time_f" do
    it "returns the time if given day is start day" do
      expect(events[0].start_time_f Date.new(2014, 8, 27)).to eq "12:00"
      expect(events[0].start_time_f Date.new(2014, 8, 28)).to eq "..."
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
