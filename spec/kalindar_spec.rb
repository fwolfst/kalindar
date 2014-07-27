require 'spec_helper'

describe Kalindar do
  it 'has a version number' do
    expect(Kalindar::VERSION).not_to be nil
  end

  it 'does something useful' do
    expect(false).to eq(true)
  end
end

describe EventCalendar do
  it 'parses an ics file' do
    cal = EventCalendar.new 'spec/testcal.ics'
  end

  it 'finds events given date' do
    cal = EventCalendar.new 'spec/testcal.ics'
    events = cal.find_events (Date.new(2014, 07, 27))
    event_names = events.map(&:summary)
    expect(event_names.include? "onehour").to eq true
    expect(event_names.include? "allday").to eq true
  end
end
