class HomeController < ApplicationController
  def index
    @current_date = Date.current.strftime("%d %B")
    @days_of_week = Date::DAYNAMES
  end

  def show_schedule
    @day = params[:day]
    # Здесь должна быть логика загрузки расписания для @day
    
    @schedule = Schedule.where(day: @day) # Пример фильтрации
    render partial: 'daily_schedule'
  end
end
