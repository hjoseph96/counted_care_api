class CreateResources < ActiveRecord::Migration[8.0]
  def change
    create_table :resources, id: :uuid do |t|
      t.string :title
      t.string :category
      t.string :description
      t.string :link, null: true
      t.boolean :is_favorite, null: true
      t.integer :resource_type, null: false
      t.string :partner_name, null: true
      t.text :tags, array: true, default: [], null: true
      t.text :zip_regions, array: true, default: [], null: true

      t.timestamps
    end
  end
end
