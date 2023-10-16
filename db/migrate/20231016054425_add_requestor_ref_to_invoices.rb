class AddRequestorRefToInvoices < ActiveRecord::Migration[6.1]
  def change
    add_reference :invoices, :requestor, null: false, foreign_key: true
  end
end
