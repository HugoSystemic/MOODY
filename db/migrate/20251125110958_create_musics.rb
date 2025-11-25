class CreateMusics < ActiveRecord::Migration[7.1]
  def change
    create_table :musics do |t|
      t.references :user, null: false, foreign_key: true
      t.references :chat, null: false, foreign_key: true
      t.string :video_url
      t.string :title
      t.string :mood
      t.integer :duration_minutes
      t.boolean :liked

      t.timestamps
    end
  end
end
