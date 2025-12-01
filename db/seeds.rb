puts "Cleaning database..."

Music.destroy_all
Chat.destroy_all
User.destroy_all

puts "Creating users..."

alice = User.create!(email: "alice@example.com", password: "123456")
bob   = User.create!(email: "bob@example.com", password: "987654")

puts "Created #{User.count} users."

puts "Creating chats..."

chat_alice = Chat.create!(user: alice, title: "Session Etude", activity: "Etudier", mood: "Calme", duration: 30, liked: false)
chat_bob   = Chat.create!(user: bob, title: "Session Sport", activity: "Sport", mood: "Énergique", duration: 20, liked: false)

puts "Created #{Chat.count} chats."

puts "Creating musics..."
musics = [
  { title: "Clair de lune", video_url: "https://www.youtube.com/watch?v=4Tr0otuiQuU", category: "Calme", duration_minutes: 5, liked: false, chat: chat_alice },
  { title: "Weightless",   video_url: "https://www.youtube.com/watch?v=UfcAVejslrU", category: "Relax", duration_minutes: 8, liked: false, chat: chat_alice },
  { title: "Eye of the Tiger", video_url: "https://www.youtube.com/watch?v=btPJPFnesV4", category: "Énergique", duration_minutes: 4, liked: false, chat: chat_bob },
  { title: "Happy", video_url: "https://www.youtube.com/watch?v=ZbZSe6N_BXs", category: "Joy", duration_minutes: 3, liked: false, chat: chat_bob },
  { title: "Dreams", video_url: "https://www.youtube.com/watch?v=mrZRURcb1cM", category: "Réfléchi", duration_minutes: 6, liked: false, chat: chat_alice }
]

musics.each do |m|
  Music.create!(m)
end

puts "Created #{Music.count} musics."

puts "Seed finished! ✅"

puts "Users, chats, and musics are ready for testing your app."
