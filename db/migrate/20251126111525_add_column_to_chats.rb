class AddColumnToChats < ActiveRecord::Migration[7.1]
  def change
    add_column :chats, :mood, :string
    add_column :chats, :activity, :string
    add_column :chats, :duration, :integer
    add_column :chats, :liked, :boolean
  end
end
