class RemoveUserFromMusics < ActiveRecord::Migration[7.1]
  def change
    remove_reference :musics, :user, foreign_key: true
  end
end
