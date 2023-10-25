FactoryBot.define do
  factory :invoice_detail do
    subject { "テスト費1" }
    unit_price { 1 }
    quantity { 10000 }
    invoice_id {}
  end
end