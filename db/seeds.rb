puts "Cleaning database..."

Music.destroy_all
Chat.destroy_all
User.destroy_all

puts "Creating users..."

alice = User.create!(email: "alice@example.com", password: "123456")
bob   = User.create!(email: "bob@example.com", password: "987654")

puts "Created #{User.count} users."

puts "Creating chats..."

chat_alice = Chat.create!(user: alice, title: "Session Revision")
chat_bob   = Chat.create!(user: bob, title: "Session Sport")

puts "Created #{Chat.count} chats."

puts "Creating musics..."
musics = [
  { user: alice, chat: chat_alice, title: "Clair de lune", video_url: "https://www.youtube.com/watch?v=4Tr0otuiQuU", mood: "Calme", duration_minutes: 5, liked: false },
  { user: alice, chat: chat_alice, title: "Weightless",   video_url: "https://www.youtube.com/watch?v=UfcAVejslrU", mood: "Relax", duration_minutes: 8, liked: false },
  { user: bob,   chat: chat_bob,   title: "Eye of the Tiger", video_url: "https://www.youtube.com/watch?v=btPJPFnesV4", mood: "Énergique", duration_minutes: 4, liked: false },
  { user: bob,   chat: chat_bob,   title: "Happy", video_url: "https://www.youtube.com/watch?v=ZbZSe6N_BXs", mood: "Joy", duration_minutes: 3, liked: false },
  { user: alice, chat: chat_alice, title: "Dreams", video_url: "https://www.youtube.com/watch?v=mrZRURcb1cM", mood: "Réfléchi", duration_minutes: 6, liked: false }
]

musics.each do |m|
  Music.create!(m)
end

puts "Created #{Music.count} musics."

puts "Seed finished !"
