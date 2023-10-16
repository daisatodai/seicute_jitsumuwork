class User < ApplicationRecord
  authenticates_with_sorcery!
  has_many :invoices, dependent: :destroy

  validates :password, length: { minimum: 6 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }
  validates :email, uniqueness: true
  validates :role, presence: true
  enum role: {一般ユーザー: 0, 管理者: 5}

  before_update :must_not_update_last_one_admin
  before_destroy :must_not_destroy_last_one_admin

  private

  def must_not_update_last_one_admin
    if User.where(role: 5).count <= 1 && self.will_save_change_to_attribute?("role", from: 5, to:0)
      throw :abort
    end
  end

  def must_not_destroy_last_one_admin
    if User.where(role: 5).count <= 1 && self.role == "管理者"
      throw :abort
    end
  end
end