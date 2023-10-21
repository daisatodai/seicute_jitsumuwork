class InvoiceDetail < ApplicationRecord
  belongs_to :invoice
  validates :subject, presence: true
  validates :unit_price, presence: true
  validates :quantity, presence: true
end
