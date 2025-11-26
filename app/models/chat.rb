class Chat < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy
  has_many :musics, dependent: :destroy

  def parameters_complete?
    activity.present? && mood.present? && duration_minutes.present?
  end
end
