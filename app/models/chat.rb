class Chat < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy
  has_many :musics, dependent: :destroy

  DEFAULT_TITLE = "Untitled"

  def generate_title_from_first_message
    title_prompt = <<~PROMPT
      Génère un titre court et descriptif (3 à 6 mots) en français pour une conversation de chat.
      Le titre doit résumer : humeur "#{mood}", activité "#{activity}", durée #{duration} secondes.
      Exemple : "Humeur joyeuse pour un trajet en voiture d'1h"
      Réponds UNIQUEMENT avec le titre, sans guillemets ni ponctuation finale.
    PROMPT
    first_two_user_messages = messages.where(role: "user").order(:created_at).limit(2)
    return if first_two_user_messages.empty?

    response = RubyLLM.chat.with_instructions(title_prompt).ask(first_two_user_messages.pluck(:content).join("\n"))
    puts "Titre généré : #{response.content}"
    update(title: response.content) if response.content.present?
  end
end
