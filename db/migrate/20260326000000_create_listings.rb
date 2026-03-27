class CreateListings < ActiveRecord::Migration[7.0]
  def change
    create_table :listings do |t|
      t.string :listing_number, null: false
      t.decimal :price, precision: 15, scale: 2
      t.string :status

      t.timestamps
    end
    # Agregamos un índice único en la base de datos para evitar concurecia de inserciones duplicadas (Race Conditions)
    add_index :listings, :listing_number, unique: true
  end
end
