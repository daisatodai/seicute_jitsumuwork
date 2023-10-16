class CreateInvoiceDetails < ActiveRecord::Migration[6.1]
  def change
    create_table :invoice_details do |t|
      t.string :subject, null: false
      t.integer :unit_price, null: false
      t.integer :quantity, null: false

      t.timestamps
    end
  end
end
