class AddInvoiceRefToInvoiceDetails < ActiveRecord::Migration[6.1]
  def change
    add_reference :invoice_details, :invoice, null: false, foreign_key: true
  end
end
