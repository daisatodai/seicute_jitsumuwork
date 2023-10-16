class Requestor < ApplicationRecord
  has_many :invoices, dependent: :destroy
  validates :name, presence: true, uniqueness: true
end
