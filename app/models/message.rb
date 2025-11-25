class Message < ApplicationRecord
  belongs_to :Chat

  validates :content, presence: true
  validates :role, presence: true, inclusion: { in: %w[user assistant] }
end
