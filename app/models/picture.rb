class Picture < ApplicationRecord
  belongs_to :invoice
  validates :image, presence: true
  mount_uploader :image, ImageUploader
end
