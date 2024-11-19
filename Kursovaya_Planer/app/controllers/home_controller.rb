class HomeController < ApplicationController
  def index
    I18n.locale = :ru

    # Устанавливаем текущую дату
    @current_date = params[:date].present? ? Date.parse(params[:date]) : Date.current

    # Задачи пользователя
    @tasks = Task.where(user_id: current_user.id, start_time: @current_date.beginning_of_day..@current_date.end_of_day).order(:start_time)

    # Даты и дни недели
    start_of_week = @current_date.beginning_of_week
    @days_of_week = I18n.t('date.day_names') # Дни недели на русском
    @week_dates = (0..6).map { |i| start_of_week + i } # Даты текущей недели

    # Добавляем стандартные задачи (Пробуждение и Сон)
    @tasks = (default_tasks_for_today + @tasks).sort_by(&:start_time)
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

  private

  def default_tasks_for_today
    [
    Task.new(
      title: "Пробуждение",
      start_time: @current_date.to_datetime + 7.hours,
      end_time: @current_date.to_datetime + 7.hours + 5.minutes
    ),
    Task.new(
      title: "Сон",
      start_time: @current_date.to_datetime + 23.hours,
      end_time: @current_date.to_datetime + 23.hours + 30.minutes
    )
  ]
  end
end
