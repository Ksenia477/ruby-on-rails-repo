class HomeController < ApplicationController
  def index
    I18n.locale = :ru
    @current_date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @current_date_formatted = @current_date.strftime("%d %B").mb_chars.downcase.to_s


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

  def optimize_schedule
    current_date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    tasks = Task.where(user_id: current_user.id, start_time: current_date.beginning_of_day..current_date.end_of_day).order(:start_time)
    grouped_tasks = tasks.group_by(&:hashtag).reject { |hashtag, tasks| hashtag.nil? || tasks.size < 2 }
    suggestions = []

    grouped_tasks.each do |hashtag, tasks|
      tasks.each_cons(2) do |task1, task2|
        # Проверка: задачи уже стоят рядом
        if task1.end_time == task2.start_time
          next
        end

        # Вариант 1: Переместить task2 сразу после task1
        task2_duration = task2.end_time - task2.start_time
        new_start_time1 = task1.end_time
        new_end_time1 = new_start_time1 + task2_duration

        # Вариант 2: Переместить task1 сразу перед task2
        task1_duration = task1.end_time - task1.start_time
        new_end_time2 = task2.start_time
        new_start_time2 = new_end_time2 - task1_duration

        suggestions << {
          task_title: task2.title,
          task_id: task2.id,
          current_time: "#{task2.start_time.strftime('%H:%M')} - #{task2.end_time.strftime('%H:%M')}",
          option_1: "#{new_start_time1.strftime('%H:%M')} - #{new_end_time1.strftime('%H:%M')}",
          option_2: "#{new_start_time2.strftime('%H:%M')} - #{new_end_time2.strftime('%H:%M')}"
        }
      end
    end

    render json: { suggestions: suggestions.uniq }
  end


  def apply_optimization
    task = Task.find(params[:task_id])
    current_date = Date.parse(params[:date]) # Получение даты из параметров
    new_start_time = Time.parse(params[:start_time]).change(year: current_date.year, month: current_date.month, day: current_date.day)
    new_end_time = Time.parse(params[:end_time]).change(year: current_date.year, month: current_date.month, day: current_date.day)

    if task.update(start_time: new_start_time, end_time: new_end_time)
      render json: { message: "Задача обновлена успешно" }
    else
      render json: { message: "Ошибка обновления задачи: #{task.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
    end
  end



  def shift_schedule
    tasks = Task.where(user_id: current_user.id, start_time: @current_date.beginning_of_day..@current_date.end_of_day).order(:start_time)

    tasks.each_cons(2) do |task1, task2|
      # Проверяем пересечение задач
      if task1.end_time > task2.start_time
        # Вычисляем разницу и сдвигаем task2
        diff = task1.end_time - task2.start_time
        task2.start_time += diff
        task2.end_time += diff
        unless task2.save
          render json: { error: "Ошибка при сохранении задачи #{task2.title}" }, status: :unprocessable_entity
          return
        end
      end
    end

    render json: { message: "Расписание обновлено успешно." }, status: :ok
  rescue StandardError => e
    render json: { error: "Ошибка: #{e.message}" }, status: :unprocessable_entity
  end

  def merge_tasks
    task1 = Task.find(params[:task1_id])
    task2 = Task.find(params[:task2_id])

    task1.update!(description: "#{task1.description}\n#{task2.description}")
    task2.destroy

    render json: { message: "Задачи объединены." }
  end

  def transfer_task
    task = Task.find(params[:task_id])
    new_time = DateTime.parse(params[:destination_time])
    task.update!(start_time: new_time)

    render json: { message: "Задача перенесена." }
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
