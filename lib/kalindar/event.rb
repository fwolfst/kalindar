require 'delegate'

# Delegator with some handy shortcuts
class Event < SimpleDelegator
  def start_time_f day
    puts "start #{start_time} : #{start_time.class} #{start_time.to_date} #{day}"
    return start_time.strftime('%H:%M') if start_time.to_date == day.to_date
    return "..."
  end
  def finish_time_f day
    return finish_time.strftime('%H:%M') if finish_time.to_date == day.to_date
    return "..."
  end
  def time_f day
    start = start_time_f day
    finish = finish_time_f day
    if start == finish && start == "..."
      "..."
    else
      "#{start_time_f day} - #{finish_time_f day}"
    end
  end
  def from_to_f
    return "#{dtstart.to_datetime.strftime("%d.%m. %H:%M")} - #{dtend.to_datetime.strftime("%d.%m. %H:%M")}"
  end
end
