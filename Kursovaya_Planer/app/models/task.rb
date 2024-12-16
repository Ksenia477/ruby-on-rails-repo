class Task < ApplicationRecord
  belongs_to :user

  validates :title, presence: { message: "не может быть пустым" }
  validate :start_time_before_end_time

  private

  def start_time_before_end_time
    if start_time.present? && end_time.present? && start_time >= end_time
      errors.add(:start_time, "должно быть меньше времени окончания")
    end
  end
  # validates :hashtag, presence: true, allow_nil: true

  # # Разрешаем массовое присваивание для поля hashtag
  # attr_accessor :hashtag
end
