class CreatePosts < ActiveRecord::Migration
  def up
    create_table :posts do |t|
      t.string :title
      t.text :body
      t.string :image_path
      t.timestamps
    end
  end
 
  def down
    drop_table :posts
  end
end