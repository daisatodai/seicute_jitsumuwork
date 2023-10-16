class CreateRequestors < ActiveRecord::Migration[6.1]
  def change
    create_table :requestors do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
