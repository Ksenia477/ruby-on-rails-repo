class HomeController < ApplicationController
  def index
    I18n.locale = :ru
    @current_date = params[:date].present? ? Date.parse(params[:date]) : Date.current

    if current_user
      # Загружаем задачи пользователя
      @tasks = Task.where(user_id: current_user.id, start_time: @current_date.beginning_of_day..@current_date.end_of_day).order(:start_time)
    else
      # Неавторизованные пользователи видят только "Пробуждение" и "Сон"
      @tasks = default_tasks_for_today.select { |task| task.user_id.nil? }
    end

    start_of_week = @current_date.beginning_of_week
    @days_of_week = I18n.t('date.day_names')
    @week_dates = (0..6).map { |i| start_of_week + i }

    @tasks = (@tasks + default_tasks_for_today).uniq.sort_by(&:start_time)
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
      Task.find_or_initialize_by(
        title: "Пробуждение",
        start_time: @current_date.to_datetime + 7.hours,
        end_time: @current_date.to_datetime + 7.hours + 5.minutes,
        user_id: current_user&.id # Привязываем к пользователю
      ).tap { |task| task.save if task.new_record? },
      Task.find_or_initialize_by(
        title: "Сон",
        start_time: @current_date.to_datetime + 23.hours,
        end_time: @current_date.to_datetime + 23.hours + 30.minutes,
        user_id: current_user&.id # Привязываем к пользователю
      ).tap { |task| task.save if task.new_record? }
    ]
  end
end
