class Event < SimpleDelegator
  def start_time_f day
    return start_time.strftime('%H:%M') if start_time.to_date == day
    return ""
  end
  def finish_time_f day
    return finish_time.strftime('%H:%M') if finish_time.to_date == day
    return ""
  end
end
