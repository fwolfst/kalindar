require 'time'

class Timespan
  attr_accessor :start
  attr_accessor :finish

  def initialize start, finish
    @start = start
    @finish = finish
  end

  def spans? date
    @start <= date && @finish >= date
  end

  def self.from_day date
    start = DateTime.new date.year, date.month, date.day, 0, 0
    finish = DateTime.new date.year, date.month, date.day, 23, 59
    Timsepan.new start, finish
  end

  # Return Timespan from start to end of start (day).
  def self.day_end start
    finish = DateTime.new start.year, start.month, start.day, 23, 59
    Timespan.new start, finish
  end
end
