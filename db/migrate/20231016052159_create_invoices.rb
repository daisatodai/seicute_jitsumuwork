class CreateInvoices < ActiveRecord::Migration[6.1]
  def change
    create_table :invoices do |t|
      t.string :subject, null: false
      t.date :issued_on, null: false
      t.date :due_on, null: false
      t.text :error
      t.integer :google_drive_api_status, null: false, default: 0
      t.integer :freee_api_status, null: false, default: 0
      t.text :memo

      t.timestamps
    end
  end
end
