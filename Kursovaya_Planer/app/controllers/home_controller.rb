class HomeController < ApplicationController
  def index
    I18n.locale = :ru
    @current_date = I18n.l(Date.current, format: "%d %B")
    @days_of_week = I18n.t('date.day_names').rotate(0)

    @dates_of_week = (0..6).map { |i| I18n.l(Date.current + i, format: "%d %B") }
  end

  def show_schedule
    I18n.locale = :ru
    day_index = params[:day].to_i
    @day = I18n.t('date.day_names').rotate(0)[day_index]
    render partial: 'daily_schedule'
  end

  def save_schedule
    day = params[:day]
    tasks = params[:tasks]

    tasks.each do |time, description|
      Schedule.create(day: day, time: time, description: description)
    end

    render plain: "Задачи сохранены."
  end
end
