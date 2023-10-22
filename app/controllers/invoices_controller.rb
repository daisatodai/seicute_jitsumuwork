class InvoicesController < ApplicationController
  before_action :admin?, only: %i[edit update destroy]
  before_action :auth_google_drive
  before_action :get_freee_authentication_code, only: %i[index new edit]
  
  def index
    get_freee_access_token
    # freeeとの疎通確認
    check_freee_connection
    @invoices = Invoice.all.includes(:requestor).order("created_at DESC")
    @invoices = @invoices.page(params[:page]).per(15)
  end

  def new
    # アクセストークンが初回かの判定
    get_freee_access_token
    # freeeとの疎通確認
    check_freee_connection
    @invoice = Invoice.new
    @requestor = Requestor.new
    1.times {@invoice.invoice_details.build}
    1.times {@invoice.pictures.build}
  end

  def create
    # アクセストークンが初回かの判定
    get_freee_access_token
    # freeeとの疎通確認
    check_freee_connection
    @invoice = Invoice.new(invoice_params)
    @invoice.user_id = current_user.id
    # 画像保存に先立って、pictures_attributesパラメーターに値が入っているかの確認
    if params[:invoice][:pictures_attributes]
      pictures_attributes_numbers = params[:invoice][:pictures_attributes].keys
      files = []
      pictures_attributes_numbers.each do |number|
        if params[:invoice][:pictures_attributes][:"#{number}"][:image]
          file = params[:invoice][:pictures_attributes][:"#{number}"][:image]
          files << file
        end
      end
      # 請求書の保存が成功した場合の処理
      if @invoice.save
        # Google Driveへの画像連携処理開始
        # 格納先のフォルダーの存在を確認し、なければ作成する
        top_folder = @drive.file_by_id(ENV['GOOGLE_DRIVE_TOP_LEVEL_FOLDER_ID'])
        year = params[:invoice][:issued_on][0, 4] + "年"
        month = params[:invoice][:issued_on][5, 2] + "月"
        if top_folder.file_by_title(year)
          second_level_folder = top_folder.file_by_title(year)
          if second_level_folder.file_by_title(month)
            third_level_folder = second_level_folder.file_by_title(month)
          else
            third_level_folder = second_level_folder.create_subfolder(month)
          end
        else
          second_level_folder = top_folder.create_subfolder(year)
          third_level_folder = second_level_folder.create_subfolder(month)
        end
        # 画像ファイルのアップロード処理
        files.each.with_index do |file, index|
          filename = "#{year}#{month}_#{params[:invoice][:subject]}_#{index + 1}"
          file_ext = File.extname(filename)
          file_find = third_level_folder.upload_from_file(File.absolute_path(file), filename, convert: false)
        end
        # Google Driveへの画像連携処理終了
        # 成功したかのチェック
        file_upload_checks = []
        files.length.times do |i|
          filename = "#{year}#{month}_#{params[:invoice][:subject]}_#{i + 1}"
          file_upload_checks << @drive.file_by_title(filename)
        end
        if file_upload_checks.include?(nil)
          file = nil
        else # 成功した場合picturesテーブルに保存されたレコードをすぐに呼び出して、google_drive_urlカラムを更新する
          pictures = Picture.where(invoice_id: @invoice.id)
          pictures.each.with_index do |picture, index|
            filename = "#{year}#{month}_#{params[:invoice][:subject]}_#{index + 1}"
            file = @drive.file_by_title(filename)
            picture.update(google_drive_url: "https://drive.google.com/uc?export=view&id=#{file.id}", google_drive_file_id: file.id)
          end
          invoice = Invoice.find(@invoice.id)
          invoice.update(google_drive_api_status: 1)
        end
        # freeeへの請求書内容連携処理開始
        deal_url  = "https://api.freee.co.jp/api/1/deals"
        connection = Faraday::Connection.new(url: deal_url) do|conn|
          conn.request :url_encoded
          conn.adapter Faraday.default_adapter
        end
        # リクエストボディに入れるdetailsをあらかじめ整形
        @invoice_details = InvoiceDetail.where(invoice_id: @invoice.id)
        details = []
        @invoice_details.each do |invoice_detail|
          description = invoice_detail.subject
          amount = (invoice_detail.unit_price * invoice_detail.quantity * 1.10).to_i
          details << {
            "tax_code": 136,
            "account_item_id": 767592023,
            "amount": amount,
            "description": description
          }
        end
        # POSTメソッドでfreeeに連携
        response = connection.post do |request|
          request.options.timeout = 300
          request.headers["Content-Type"] = "application/json"
          request.headers["Authorization"] = "Bearer #{session[:access_token]}"
          request.body = {
            "issue_date": @invoice.issued_on,
            "type": "expense",
            "company_id": ENV["FREEE_COMPANY_ID"],
            "due_date": @invoice.due_on,
            "details": details
          }.to_json
        end
        # freeeへの請求書内容連携処理終了
        # 成功したかのチェック
        if response.status == 201
          invoice = Invoice.find(@invoice.id)
          response_body = JSON.parse(response.body.force_encoding("UTF-8"))
          freee_deal_id = response_body.values[0]["id"]
          invoice.update(freee_api_status: 1, freee_deal_id: freee_deal_id)
        else
          error = JSON.parse(response.body.force_encoding("UTF-8"))
          if response.status == 400 || response.status == 404 || response.status == 500
            error1 = error.values[1][0]["messages"][0]
            error2 = ""
          elsif response.status == 401 || response.status == 403
            error1 = error["message"]
            error2 = error["code"]
          end
          errors = []
          errors << error1
          errors << error2
          invoice = Invoice.find(@invoice.id)
          invoice.update(error: error1+error2)
        end
        status = response.status
        # 最終判定
        if file == nil && status != 201
          flash[:info] = "請求書を登録しました。画像のアップロードに失敗しました。freeeへの連携に失敗しました。#{error1}#{error2}"
          redirect_to invoices_path
        elsif file == nil
          flash[:info] = "請求書を登録しました。画像のアップロードに失敗しました。"
          redirect_to invoices_path
        elsif status != 201
          flash[:info] = "請求書を登録しました。freeeへの連携に失敗しました。#{error1}#{error2}"
          redirect_to invoices_path
        else
          flash[:success] = "請求書を登録しました。"
          redirect_to invoices_path
        end
      # 請求書の保存が失敗した場合
      else
        flash.now[:danger] = "請求書の登録に失敗しました"
        render :new
      end
    end
  end

  def show
    @invoice = Invoice.find(params[:id])
    @pictures = Picture.where(invoice_id: params[:id])
    @subtotal = @invoice.subtotal_price_without_tax
    @total = @invoice.total_price_with_tax
  end

  def edit
    # アクセストークンが初回かの判定
    get_freee_access_token
    # freeeとの疎通確認
    check_freee_connection
    @invoice = Invoice.find(params[:id])
    @pictures = Picture.where(invoice_id: params[:id])
  end

  def update
    # アクセストークンが初回かの判定
    get_freee_access_token
    # freeeとの疎通確認
    check_freee_connection
    @invoice = Invoice.find(params[:id])
    # Google Driveへの連携準備として、pictures_attributesパラメーターの値を取得
    params[:invoice][:pictures_attributes]
    pictures_attributes_numbers = params[:invoice][:pictures_attributes].keys
    picture_ids = []
    images = []
    pictures_attributes_numbers.each do |number|
      if params[:invoice][:pictures_attributes][:"#{number}"][:id] # idがあった場合
        picture_id = params[:invoice][:pictures_attributes][:"#{number}"][:id]
        picture_ids << picture_id
      elsif params[:invoice][:pictures_attributes][:"#{number}"]
        image = params[:invoice][:pictures_attributes][:"#{number}"][:image]
        images << image
      end
    end
    # 更新前にinvoiceに紐づいていた全てのpicturesをGoogle Driveから削除
    pictures = Picture.where(invoice_id: @invoice.id)
    files = []
    pictures.each do |picture|
      begin
        file = @drive.file_by_id(picture.google_drive_file_id)
      rescue
        next
      end
      file = file.delete(permanent = true)
      begin
        files << @drive.file_by_id(picture.google_drive_file_id)
      rescue
        files << nil
      end
    end
    file_checks = files.compact
    # 請求書の更新が成功した場合の処理
    if @invoice.update(invoice_params)
      # Google Driveへの画像連携処理開始
      # 次に、最新のinvoiceに紐づいている全てのpicturesを取得し、Google Driveにアップロード
      pictures = Picture.where(invoice_id: @invoice.id)
      # 格納先のフォルダーの存在を確認し、なければ作成する
      top_folder = @drive.file_by_id(ENV['GOOGLE_DRIVE_TOP_LEVEL_FOLDER_ID'])
        year = params[:invoice][:issued_on][0, 4] + "年"
        month = params[:invoice][:issued_on][5, 2] + "月"
        if top_folder.file_by_title(year)
          second_level_folder = top_folder.file_by_title(year)
          if second_level_folder.file_by_title(month)
            third_level_folder = second_level_folder.file_by_title(month)
          else
            third_level_folder = second_level_folder.create_subfolder(month)
          end
        else
          second_level_folder = top_folder.create_subfolder(year)
          third_level_folder = second_level_folder.create_subfolder(month)
        end
      # 画像ファイルのアップロード処理
      pictures.each.with_index do |picture, index|
        picture_name = "#{year}#{month}_#{params[:invoice][:subject]}_#{index + 1}"
        file_ext = File.extname(picture_name)
        file = picture.image.instance_variable_get(:@file)
        file_path = file.instance_variable_get(:@file)
        file_find = third_level_folder.upload_from_file(file_path, picture_name, convert: false)
      end
      # Google Driveへの画像連携処理終了
      # 成功したかのチェック
      file_upload_checks = []
      pictures.length.times do |i|
        picture_name = "#{year}#{month}_#{params[:invoice][:subject]}_#{i + 1}"
        file_upload_checks << @drive.file_by_title(picture_name)
      end
      if file_upload_checks.include?(nil)
        file = nil
        invoice = Invoice.find(@invoice.id)
        invoice.update(google_drive_api_status: 0)
      else # 成功した場合picturesテーブルに保存されたレコードをすぐに呼び出して、google_drive_urlカラムを更新する
        pictures = Picture.where(invoice_id: @invoice.id)
        pictures.each.with_index do |picture, index|
          picture_name = "#{year}#{month}_#{params[:invoice][:subject]}_#{index + 1}"
          file = @drive.file_by_title(picture_name)
          picture.update(google_drive_url: "https://drive.google.com/uc?export=view&id=#{file.id}")
          picture.update(google_drive_file_id: file.id)
        end
        invoice = Invoice.find(@invoice.id)
        invoice.update(google_drive_api_status: 1)
      end
      # freeeへの請求書内容連携処理開始
      freee_deal_id = @invoice.freee_deal_id
      if freee_deal_id.present? #更新かどうか確認
        deal_url  = "https://api.freee.co.jp/api/1/deals/#{freee_deal_id}"
        connection = Faraday::Connection.new(url: deal_url) do|conn|
          conn.request :url_encoded
          conn.adapter Faraday.default_adapter
        end
        # リクエストボディに入れるdetailsをあらかじめ整形
        @invoice_details = InvoiceDetail.where(invoice_id: @invoice.id)
        details = []
        @invoice_details.each do |invoice_detail|
          description = invoice_detail.subject
          amount = (invoice_detail.unit_price * invoice_detail.quantity * 1.10).to_i
          details << {
            "tax_code": 136,
            "account_item_id": 767592023,
            "amount": amount,
            "description": description
          }
        end
        # PUTメソッドでfreeeに連携
        response = connection.put do |request|
          request.options.timeout = 300
          request.headers["Content-Type"] = "application/json"
          request.headers["Authorization"] = "Bearer #{session[:access_token]}"
          request.body = {
            "issue_date": @invoice.issued_on,
            "type": "expense",
            "company_id": ENV["FREEE_COMPANY_ID"],
            "due_date": @invoice.due_on,
            "details": details
          }.to_json
        end
      else # 初回であれば、POSTメソッドでお来る
        deal_url  = "https://api.freee.co.jp/api/1/deals"
        connection = Faraday::Connection.new(url: deal_url) do|conn|
          conn.request :url_encoded
          conn.adapter Faraday.default_adapter
        end
        # リクエストボディに入れるdetailsをあらかじめ整形
        @invoice_details = InvoiceDetail.where(invoice_id: @invoice.id)
        details = []
        @invoice_details.each do |invoice_detail|
          description = invoice_detail.subject
          amount = (invoice_detail.unit_price * invoice_detail.quantity * 1.10).to_i
          details << {
            "tax_code": 136,
            "account_item_id": 767592023,
            "amount": amount,
            "description": description
          }
        end
        # POSTメソッドでfreeeに連携
        response = connection.post do |request|
          request.options.timeout = 300
          request.headers["Content-Type"] = "application/json"
          request.headers["Authorization"] = "Bearer #{session[:access_token]}"
          request.body = {
            "issue_date": @invoice.issued_on,
            "type": "expense",
            "company_id": ENV["FREEE_COMPANY_ID"],
            "due_date": @invoice.due_on,
            "details": details
          }.to_json
        end
      end
      # freeeへの請求書内容連携処理終了
      # 成功したかレスポンスをチェック
      if response.status == 200 || response.status == 201
        invoice = Invoice.find(@invoice.id)
        invoice.update(freee_api_status: 1, error: nil)
      else
        if response.status == 400 || response.status == 404 || response.status == 500
          error = JSON.parse(response.body.force_encoding("UTF-8"))
          error1 = error.values[1][0]["messages"][0]
          error2 = ""
        elsif response.status == 401 || response.status == 403
          error = JSON.parse(response.body.force_encoding("UTF-8"))
          error1 = error["message"]
          error2 = error.values["messages"]
        end
        errors = []
        errors << error1
        errors << error2
        invoice = Invoice.find(@invoice.id)
        invoice.update(freee_api_status: 0, error: error1+error2)
      end
      status = response.status
      # 最終判定
      if file == nil && status != 200 && status != 201
        flash[:info] = "#{@invoice.subject}を更新しました。画像のアップロードに失敗しました。手動でGoogle Driveに登録してください。ファイル名は yyyy年mm月_件名_何枚目.拡張子 です。freeeへの連携に失敗しました。#{error1}#{error2}"
        redirect_to invoices_path
      elsif file == nil
        flash[:info] = "#{@invoice.subject}を更新しました。画像のアップロードに失敗しました。手動でGoogle Driveに登録してください。ファイル名は yyyy年mm月_件名_何枚目.拡張子 です。"
        redirect_to invoices_path
      elsif status != 200 && status != 201
        flash[:info] = "#{@invoice.subject}を更新しました。freeeへの連携に失敗しました。#{error1}#{error2}"
        redirect_to invoices_path
      else
        flash[:success] = "#{@invoice.subject}を更新しました。"
        redirect_to invoices_path
      end
    # 請求書の保存が失敗した場合
    else
      flash.now[:danger] = "更新に失敗しました"
      render :edit
    end
  end

  def destroy
    @invoice = Invoice.find(params[:id])
    pictures = Picture.where(invoice_id: @invoice.id)
    # Google Drive上の画像ファイルを完全削除
    files = []
    pictures.each do |picture|
      begin
        file = @drive.file_by_id(picture.google_drive_file_id)
      rescue
        next
      end
        file = file.delete(permanent = true)
        begin
        files << @drive.file_by_id(picture.google_drive_file_id)
      rescue
        files << nil
      end
    end
    file_delete_checks = files.compact
    if file_delete_checks.present?
      invoice = Invoice.find(@invoice.id)
      invoice.update(google_drive_api_status: 1)
    end
    # freee上の請求書内容を完全削除
    freee_deal_id = @invoice.freee_deal_id
    if @invoice.freee_deal_id.present?
      deal_url  = "https://api.freee.co.jp/api/1/deals/#{freee_deal_id}"
      connection = Faraday::Connection.new(url: deal_url) do|conn|
        conn.request :url_encoded
        conn.adapter Faraday.default_adapter
      end
      response = connection.delete do |request|
        request.options.timeout = 300
        request.headers["Content-Type"] = "application/json"
        request.headers["Authorization"] = "Bearer #{session[:access_token]}"
        request.body = {
          "id": freee_deal_id,
          "company_id": ENV["FREEE_COMPANY_ID"]
        }.to_json
      end
      if response.status == 200
        deal_url  = "https://api.freee.co.jp/api/1/deals/#{freee_deal_id}"
        connection = Faraday::Connection.new(url: deal_url) do|conn|
          conn.request :url_encoded
          conn.adapter Faraday.default_adapter
        end
        response = connection.delete do |request|
          request.options.timeout = 300
          request.headers["Content-Type"] = "application/json"
          request.headers["Authorization"] = "Bearer #{session[:access_token]}"
          request.body = {
            "id": freee_deal_id,
            "company_id": ENV["FREEE_COMPANY_ID"]
          }.to_json
        end
        # 成功したかレスポンスをチェック
        if response.status == 204
        else
          error = JSON.parse(response.body.force_encoding("UTF-8"))
          if response.status == 400 || response.status == 404 || response.status == 500
            error1 = error.values[1][0]["messages"][0]
            if error.values[1][1]["messages"][0]
              error2 = error.values[1][1]["messages"][0] unless error.values[1][1]["messages"][0] == nil
            end
          elsif response.status == 401 || response.status == 403
            error1 = error["message"]
            error2 = error["code"]
          end
          errors = []
          errors << error1
          errors << error2 unless error2 == nil
          @invoice.update(freee_api_status: 0)
          status = response.status
        end
      end
    else
      status = 204
    end
    if @invoice.destroy
      # 最終判定
      if file_delete_checks == [] && status == 204
        flash[:success] = "#{@invoice.subject}を削除しました。"
        redirect_to invoices_path
      elsif file_delete_checks != []
        flash[:info] = "#{@invoice.subject}を削除しました。Google Driveからの画像削除に失敗しました。#{file_delete_checks.name}を手動で削除してください。"
        redirect_to invoices_path
      elsif status != 204
        flash[:info] = "#{@invoice.subject}を削除しました。freeeの内容削除に失敗しました。以下のメッセージを確認し手動で削除してください。#{errors}"
        redirect_to invoices_path
      else
        flash[:info] = "#{@invoice.subject}を削除しました。Google Driveからの画像削除に失敗しました。#{file_delete_checks.name}を手動で削除してください。freeeの内容削除に失敗しました。以下のメッセージを確認し手動で削除してください。#{errors}"
        redirect_to invoices_path
      end
    else
      invoice.update(google_drive_api_status: 2)
      flash.now[:danger] = "削除に失敗しました"
      render :index
    end
  end

  private

  def invoice_params
    params.require(:invoice).permit(:requestor_id, :subject, :issued_on, :due_on, :freee_api_status, :memo, :freee_deal_id, invoice_details_attributes: [:subject, :quantity, :unit_price, :_destroy, :id], pictures_attributes: [:image, :google_drive_url, :google_drive_file_id, :_destroy, :id])
  end

  def auth_google_drive
    client = OAuth2::Client.new(
      ENV['GOOGLE_DRIVE_CLIENT_ID'], ENV['GOOGLE_DRIVE_CLIENT_SECRET'],
      site: 'https://accounts.google.com',
      token_url: '/o/oauth2/token',
      authorize_url: '/o/oauth2/auth'
    )

    @token = OAuth2::AccessToken.from_hash(
      client, { refresh_token: ENV['GOOGLE_DRIVE_REFRESH_TOKEN'], expires_at: 3600 }
    ).refresh!.token

    @drive = GoogleDrive.login_with_oauth(@token)
  end

  # 認可コードを取得
  def get_freee_authentication_code
    if session[:authentication_code]
    else
      if request.query_string.match(/code=(.*)/)
        query_string = request.query_string.match(/code=(.*)/)
        session[:authentication_code] = query_string[1]
      else
        redirect_to "https://accounts.secure.freee.co.jp/public_api/authorize?client_id=#{ENV['FREEE_CLIENT_ID']}&redirect_uri=https%3A%2F%2Fboiling-earth-04784-9dfd8063f145.herokuapp.com%2Finvoices&response_type=code&prompt=select_company", allow_other_host: true
      end
    end
  end

  # 認可コードを用いてアクセストークンを取得
  def get_freee_access_token
    if session[:access_token] == nil || session[:refresh_token] == nil
      token_url  = "https://accounts.secure.freee.co.jp/public_api/token"
      connection = Faraday::Connection.new(url: token_url) do|conn|
        conn.request :url_encoded
        conn.adapter Faraday.default_adapter
      end
      response = connection.post do |request|
        request.options.timeout = 300
        request.body = {
          grant_type: "authorization_code",
          client_id: ENV["FREEE_CLIENT_ID"],
          client_secret: ENV["FREEE_CLIENT_SECRET"],
          code: session[:authentication_code],
          redirect_uri: "https://boiling-earth-04784-9dfd8063f145.herokuapp.com/invoices"
        }
      end
      session[:access_token] = JSON.parse(response.body)["access_token"]
      session[:refresh_token] = JSON.parse(response.body)["refresh_token"]
    end
  end

  # freeeへの疎通確認
  def check_freee_connection
    tax_url  = "https://api.freee.co.jp/api/1/taxes/companies/#{ENV['FREEE_COMPANY_ID']}"
    connection = Faraday::Connection.new(url: tax_url) do|conn|
      conn.request :url_encoded
      conn.adapter Faraday.default_adapter
    end
    response = connection.get do |request|
      request.options.timeout = 300
      request.headers["Authorization"] = "Bearer #{session[:access_token]}"
      request.body = {
        grant_type: "refresh_token",
        client_id: ENV['FREEE_CLIENT_ID'],
        client_secret: ENV['FREEE_CLIENT_SECRET'],
        refresh_token: session[:refresh_token]
      }
    end
    # 疎通できなければ、リフレッシュトークンを用いてアクセストークンを更新する
    unless response.status == 200
      token_url  = "https://accounts.secure.freee.co.jp/public_api/token"
      connection = Faraday::Connection.new(url: token_url) do|conn|
        conn.request :url_encoded
        conn.adapter Faraday.default_adapter
      end
      response = connection.post do |request|
        request.options.timeout = 300
        request.body = {
          grant_type: "refresh_token",
          client_id: ENV['FREEE_CLIENT_ID'],
          client_secret: ENV['FREEE_CLIENT_SECRET'],
          refresh_token: session[:refresh_token],
          redirect_uri: "https://boiling-earth-04784-9dfd8063f145.herokuapp.com/invoices"
        }
      end
      if response.status == 200
        session[:access_token] = JSON.parse(response.body)["access_token"]
        session[:refresh_token] = JSON.parse(response.body)["refresh_token"]
      else # それでもダメなら、認証し直す
        session[:authentication_code] = nil
        session[:access_token] = nil
        session[:refresh_token] = nil
        flash[:info] = "freeeへの接続に問題があったため、再認証しました"
        redirect_to invoices_path
      end
    end
  end
end
