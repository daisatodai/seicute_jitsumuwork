class AddIndexToRequestorsName < ActiveRecord::Migration[6.1]
  def change
    add_index :requestors, :name, unique: true
  end
end
