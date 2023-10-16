class Invoice < ApplicationRecord
  has_many :invoice_details, dependent: :destroy
  has_many :pictures, dependent: :destroy
  belongs_to :user
  accepts_nested_attributes_for :invoice_details, allow_destroy: true, reject_if: lambda {|attributes| attributes['subject'].blank? and attributes['quantity'].blank? and attributes['unit_price'].blank?}
  accepts_nested_attributes_for :pictures, allow_destroy: true, reject_if: lambda {|attributes| attributes['image'].blank?}
  belongs_to :requestor
  validates :subject, presence: true
  validates :issued_on, presence: true
  validates :due_on, presence: true
  validates :api_status, presence: true
  enum api_status: { 未連携: 0, 完了: 1 }
  scope :search_by_due_on_year, -> (from, to){ where(due_on: from..to)}
  scope :search_by_due_on_month, -> (from, to){ where(due_on: from..to)}
  scope :search_by_due_on_date, -> (due_on){ where(due_on: "#{due_on}")}
  scope :search_by_subject, -> (subject){ where("subject LIKE ?", "%#{subject}%")}
  # validates :issued_on_before_type_cast, format: { with: /\A(2014)-([01]\d)-([0-3]\d)\z/ }, unless: ->(rec){ rec.due_on_before_type_cast.blank? }
  # validates :due_on_before_type_cast, format: { with: /\A(2014)-([01]\d)-([0-3]\d)\z/ }, unless: ->(rec){ rec.due_on_before_type_cast.blank? }
  # validate :start_end_check

  def start_end_check
    errors.add(:due_on, "は開始日より前の日付は登録できません。") unless self.issued_on <= self.due_on 
  end

  def subtotal_price_without_tax
    subtotal = 0
    self.invoice_details.each do |invoice_detail|
      invoice_detail.subject
      quantity = invoice_detail.quantity
      price = invoice_detail.unit_price
      sum = quantity * price
      subtotal += sum
    end
    subtotal
  end

  def total_price_with_tax
    total = 0
    self.invoice_details.each do |invoice_detail|
      invoice_detail.subject
      quantity = invoice_detail.quantity
      price = invoice_detail.unit_price
      subtotal = quantity * price
      sum = (quantity * price *1.10).to_i
      total += sum
    end
    total = total.to_i
  end

end
