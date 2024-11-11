class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
         
  ROLES = %w[user admin]

  def admin?
    role == 'admin'
  end
end
