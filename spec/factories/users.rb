FactoryBot.define do
  # 一般ユーザー
  factory :user do
    email { "test01@example.com" }
    password { "password" }
    password_confirmation { "password" }
    role { 0 }
  end
  # 管理者
  factory :second_user, class: User do
    email { "test02@example.com" }
    password { "password" }
    password_confirmation { "password" }
    role { 5 }
  end
end