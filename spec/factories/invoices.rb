FactoryBot.define do
  factory :invoice do
    subject { "テスト費" }
    issued_on { "2023-10-25" }
    due_on { "2023-10-31" }
    error {}
    google_drive_api_status { 0 }
    freee_api_status { 0 }
    memo {}
    freee_deal_id {}
    requestor_id {}
    user_id {}
  end
end