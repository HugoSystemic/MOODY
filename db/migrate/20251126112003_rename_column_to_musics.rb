class RenameColumnToMusics < ActiveRecord::Migration[7.1]
  def change
    rename_column(:musics, :mood, :category)

  end
end
