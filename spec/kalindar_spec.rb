require 'spec_helper'

describe Kalindar do
  it 'has a version number' do
    expect(Kalindar::VERSION).not_to be nil
  end
end

describe EventCalendar do
  it 'parses an ics file' do
    cal = EventCalendar.new 'spec/testcal.ics'
  end

  it 'initializes alternatively with a list of ics files' do
    cal = EventCalendar.new ['spec/testcal.ics', 'spec/testcal2.ics']
    expect(cal.calendars.length).to eql 2
  end

  it 'exposes filename of parsed calendar' do
    cal = EventCalendar.new ['spec/testcal.ics', 'spec/testcal2.ics']
    expect(cal.filename_of cal.calendars.first).to eql 'spec/testcal.ics'
  end

  it 'finds events given date' do
    cal = EventCalendar.new 'spec/testcal.ics'
    events = cal.find_events (Date.new(2014, 07, 27))
    event_names = events.map(&:summary)
    expect(event_names.include? "onehour").to eq true
    expect(event_names.include? "allday").to eq true
  end

  it 'finds events that reocur' do
    cal = EventCalendar.new 'spec/testcal.ics'
    events = cal.find_events (Date.new(2014, 07, 27))
    event_names = events.map(&:summary)
    expect(event_names.include? "daily").to eq true
  end

  it '#events_in' do
    cal = EventCalendar.new 'spec/testcal.ics'
    events = cal.events_in(Date.new(2014, 07, 27), Date.new(2014, 07, 28))
    event_names = events.map(&:summary)
    expect(event_names).to eq ["allday", "onehour", "daily", "allday", "daily"]
  end

  it '#events_in by day' do
    cal = EventCalendar.new 'spec/testcal.ics'
    events = cal.events_in(Date.new(2014, 7, 27), Date.new(2014, 7, 28))
    event_names = events.map(&:summary)
    expect(event_names).to eq ["allday", "onehour", "daily", "allday", "daily"]
    expect(event_names.class).to eq({}.class)
  end

  describe "Event" do
    describe "#start_time_f" do
      it "returns the time if given day is start day" do
        cal = EventCalendar.new 'spec/testcal.ics'
        events = cal.events_in(Date.new(2014, 8, 27), Date.new(2014, 8, 28))
        expect(Event.new(events[0]).start_time_f Date.new(2014, 8, 27)).to eq "12:00"
        expect(Event.new(events[0]).start_time_f Date.new(2014, 8, 28)).to eq ""
      end
    end
    describe "#finish_time_f" do
      it "returns the time if given day is end day" do
        cal = EventCalendar.new 'spec/testcal.ics'
        events = cal.events_in(Date.new(2014, 8, 27), Date.new(2014, 8, 28))
        expect(Event.new(events[0]).finish_time_f Date.new(2014, 8, 27)).to eq ""
        expect(Event.new(events[0]).finish_time_f Date.new(2014, 8, 28)).to eq "13:00"
      end
    end
    describe "#time_f" do
      it "returns the from to time for given day" do
        cal = EventCalendar.new 'spec/testcal.ics'
        events = cal.events_in(Date.new(2014, 8, 27), Date.new(2014, 8, 28))
        expect(Event.new(events[0]).time_f Date.new(2014, 8, 27)).to eq "12:00 - "
      end
    end
    describe "#time_f" do
      it "returns the from to time" do
        cal = EventCalendar.new 'spec/testcal.ics'
        events = cal.events_in(Date.new(2014, 8, 27), Date.new(2014, 8, 28))
        expect(Event.new(events[0]).from_to_f).to eq "27.08. 12:00 - 28.08. 13:00"
      end
    end
  end
end
