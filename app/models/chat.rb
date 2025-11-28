class Chat < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy
  has_many :musics, dependent: :destroy

  DEFAULT_TITLE = "Untitled"
  TITLE_PROMPT = <<~PROMPT
  En te basant sur l’ensemble du contexte de la conversation, génère un titre concis et pertinent (3 à 6 mots) résumant le sujet principal ou le problème central abordé.

    Exigences :
    - Retourne uniquement le titre.
    - Le titre doit être spécifique et refléter clairement le thème de la conversation.
    - Utilise le Format Titre en français (Majuscule au début + noms/adjectifs importants en minuscule).
    - Pas d’emojis, pas de guillemets, pas de ponctuation finale.
    - Si plusieurs sujets apparaissent, concentre-toi sur le thème dominant.
    - Si la conversation porte sur du dépannage, reflète le problème traité.
    - Si la conversation est très courte, déduis le sujet principal à partir des éléments disponibles.
    - Garde un ton professionnel, clair et lisible.

    Retourne uniquement le titre final.
  PROMPT

  def generate_title_from_first_message
    first_user_message = messages.where(role: "user").order(:created_at).first
    return if first_user_message.nil?

    response = RubyLLM.chat.with_instructions(TITLE_PROMPT).ask(first_user_message.content)
    puts "Titre généré : #{response.content}"
    update(title: response.content) if response.content.present?
  end
end
