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
        new_start_time2 = task1.end_time
        new_end_time2 = new_start_time2 + task2_duration

        # Вариант 2: Переместить task1 сразу перед task2
        task1_duration = task1.end_time - task1.start_time
        new_end_time1 = task2.start_time
        new_start_time1 = new_end_time1 - task1_duration

        suggestions << {
          task1: task1,
          task2: task2,
          option_1: "#{new_start_time1.strftime('%H:%M')} - #{new_end_time1.strftime('%H:%M')}",
          option_2: "#{new_start_time2.strftime('%H:%M')} - #{new_end_time2.strftime('%H:%M')}"
        }
      end
    end

    render json: { suggestions: suggestions }
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
    current_date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    tasks = Task.where(user_id: current_user.id, start_time: current_date.beginning_of_day..current_date.end_of_day).order(:start_time)

    if tasks.empty?
      render json: { message: "На текущий день задач нет." } and return
    end

    changes_made = false
    tasks.each_cons(2) do |prev_task, curr_task|
      if prev_task.end_time > curr_task.start_time
        # Пересечение найдено, сдвигаем текущую задачу
        overlap = prev_task.end_time - curr_task.start_time
        curr_task.start_time += overlap
        curr_task.end_time += overlap
        curr_task.save!
        changes_made = true
      end
    end

    if changes_made
      render json: { message: "Расписание было оптимизировано." }
    else
      render json: { message: "В расписании нет пересечений между задачами." }
    end
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
