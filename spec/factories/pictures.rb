FactoryBot.define do
  factory :picture do
    image { [ Rack::Test::UploadedFile.new(Rails.root.join('public/images/sample_invoice.png'), 'public/images/sample_invoice.png') ] }
    google_drive_url {}
    google_drive_file_id {}
    invoice_id {}
  end
end