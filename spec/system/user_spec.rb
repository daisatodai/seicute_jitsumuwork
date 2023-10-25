require 'rails_helper'
RSpec.describe 'ユーザー制御機能', type: :system do
  let!(:user1) { FactoryBot.create(:user) }
  let!(:user2) { FactoryBot.create(:second_user) }
  let!(:requestor1) { FactoryBot.create(:requestor) }
  let!(:invoice) { FactoryBot.create(:invoice, requestor_id: requestor1.id, user_id: user1.id) }
  let!(:invoice_detail) { FactoryBot.create(:invoice_detail, invoice_id: invoice.id) }
  let!(:picture) { FactoryBot.create(:picture, invoice_id: invoice.id) }
  let(:pic_path) { Rails.root.join('public/images/sample_invoice.png') }
  let(:picture) { Rack::Test::UploadedFile.new(pic_path) }

  describe 'ユーザー制御' do
    before do
      visit new_session_path
      fill_in 'email', with: 'test01@example.com'
      fill_in 'password', with: 'password'
      click_button 'ログイン'
      visit invoices_path
    end
    context '一般ユーザーが請求書を新規登録しようとした場合' do
      it '新規登録が成功すること' do
        visit new_invoice_path
        sleep 0.5
        fill_in 'invoice_subject', with: 'テスト費'
        fill_in 'invoice_invoice_details_attributes_0_subject', with: 'テスト費1'
        fill_in 'invoice_invoice_details_attributes_0_quantity', with: '1'
        fill_in 'invoice_invoice_details_attributes_0_unit_price', with: '10000'
        click_button '登録する'
        sleep 0.5
        expect(page).to have_content 'テスト費'
      end
    end
    context '一般ユーザーが請求書の詳細画面に遷移しようとした場合' do
      it '遷移できること' do
        click_link 'テスト費'
        sleep 0.5
        expect(current_path).to eq invoice_path(invoice.id)
      end
    end
    context '一般ユーザーが請求書の編集画面に遷移しようとした場合' do
      it '遷移できないこと' do
        visit edit_invoice_path(invoice.id)
        sleep 0.5
        expect(current_path).to eq invoices_path
      end
    end
    context '一般ユーザーがユーザー管理画面に遷移しようとした場合' do
      it '遷移できないこと' do
        visit users_path
        expect(current_path).to eq invoices_path
      end
    end
    context '一般ユーザーが請求元の登録画面に遷移しようとした場合' do
      it '遷移できること' do
        visit new_requestor_path
        expect(current_path).to eq new_requestor_path
      end
    end
    context '一般ユーザーが請求元の編集画面に遷移しようとした場合' do
      it '遷移できないこと' do
        visit requestors_path
        click_link '株式会社A'
        sleep 0.5
        expect(current_path).to eq invoices_path
      end
    end
  end
end
