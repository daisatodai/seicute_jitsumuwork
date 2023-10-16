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

# 請求書
subjects = ["SNS代行費", "オフィス用品代", "サービス利用費"]
# sns_contents = ["原稿執筆料(企画立案〜構成執筆〜執筆〜納品)", "原稿入稿料(8月)", "SNS(Twitter)運用費(8月))", "明日の予習する", "技術記事を読む"]
# office_contents = ["掃除機かける", "エアコンフィルターの清掃", "買い物に行く", "風呂掃除する", "洗濯する"]
# service_contents = ["Wantedlyで企業探しする", "面接練習する", "履歴書と職務経歴書をブラッシュアップする"]
issued_on_from = Date.parse('2023-01-01 00:00:00')
issued_on_to = Date.parse('2023-06-30 00:00:00')
due_on_from = Date.parse('2023-07-01 00:00:00')
due_on_to = Date.parse('2023-12-31 00:00:00')
api_statuses = [0, 1]
memos = ["", "振込時期変更の可能性あり", "金額の間違っていないか先方に確認中", "請求取り消しの可能性あり"]
requestor_ids = (1..6).to_a
user_ids = (1..10).to_a

15.times do
  subject = subjects.sample
  issued_on = rand(issued_on_from..issued_on_to)
  due_on = rand(due_on_from..due_on_to)
  api_status = api_statuses.sample
  memo = memos.sample
  requestor_id = requestor_ids.sample
  user_id = user_ids.sample
  Invoice.create!(subject: subject, issued_on: issued_on, due_on: due_on, api_status: api_status, memo: memo, requestor_id: requestor_id, user_id: user_id)
end