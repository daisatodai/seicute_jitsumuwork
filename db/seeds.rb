# 請求元
requestors = %w(株式会社A 株式会社B 山田太郎 C株式会社 日本花子 株式会社D)
6.times do |n|
  Requestor.create!(name: requestors[n])
end

# 管理者
2.times do |n|
  User.create!(email: "test0#{(n + 1).to_s}@example.com", password: "password", password_confirmation: "password", role: 5)
end

# 一般ユーザー
8.times do |n|
  User.create!(email: "test0#{(n + 3).to_s}@example.com", password: "password", password_confirmation: "password", role: 0)
end

# # 請求書
# subjects = ["SNS代行費", "オフィス用品代", "サービス利用費"]
# issued_on_from = Date.parse('2023-01-01 00:00:00')
# issued_on_to = Date.parse('2023-06-30 00:00:00')
# due_on_from = Date.parse('2023-07-01 00:00:00')
# due_on_to = Date.parse('2023-12-31 00:00:00')
# google_drive_api_statuses = [0, 1]
# freee_api_statuses = [0, 1]
# memos = ["", "振込時期変更の可能性あり", "金額の間違っていないか先方に確認中", "請求取り消しの可能性あり"]
# requestor_ids = (1..6).to_a
# user_ids = (1..10).to_a

# 15.times do
#   subject = subjects.sample
#   issued_on = rand(issued_on_from..issued_on_to)
#   due_on = rand(due_on_from..due_on_to)
#   google_drive_api_status = google_drive_api_statuses.sample
#   freee_api_status = freee_api_statuses.sample
#   memo = memos.sample
#   requestor_id = requestor_ids.sample
#   user_id = user_ids.sample
#   Invoice.create!(subject: subject, issued_on: issued_on, due_on: due_on, google_drive_api_status: google_drive_api_status, freee_api_status: freee_api_status, memo: memo, requestor_id: requestor_id, user_id: user_id)
# end

# # 請求書詳細
# details_subjects = ["原稿執筆料", "入稿料", "SNS(Twitter)運用費", "事務用品代", "クラウド利用費"]
# unit_prices = [1000..100000].to_a
# quantities = [1..20].to_a
# invoice_ids = (1..15).to_a

# details_subject = details_subjects.sample
# unit_price = unit_prices.sample
# quantity = quantities.sample
# invoice_id = invoice_ids.sample

# 40.times do |n|
#   InvoiceDetail.create!(subject: details_subject, unit_price: unit_price, quantity: quantity, invoice_id: invoice_id)
# end

# # 請求書画像
# details_subjects = ["原稿執筆料", "入稿料", "SNS(Twitter)運用費", "事務用品代", "クラウド利用費"]
# images = ["sample_invoice.png", "sample_invoice2.png"]
# invoice_ids = (1..15).to_a

# image = images.sample
# google_drive_url = "https://drive.google.com/drive/folders/1l7aQ5e_K7ibOOK7rZmIOwXHaOGmNTx_0"
# invoice_id = invoice_ids.sample

# 40.times do |n|
#   Picture.create!(image:File.open("./public/images/#{image}"), google_drive_url: google_drive_url,invoice_id: invoice_id)
# end