class SearchesController < ApplicationController
  def search
    @invoices = Invoice.all.includes(:requestor)
    if params[:search].present?
      if params[:search]["due_on(1i)"].present? && params[:search]["due_on(2i)"].present? && params[:search]["due_on(3i)"].present?
        year = params[:search]["due_on(1i)"]
        month = params[:search]["due_on(2i)"]
        date = params[:search]["due_on(3i)"]
        begin
          due_on = Date.parse(year + "-" + month + "-" + date)
        rescue
        end
        @invoices = @invoices.search_by_due_on_date(due_on)
      elsif params[:search]["due_on(1i)"].present? && params[:search]["due_on(2i)"].present?
        year = params[:search]["due_on(1i)"]
        month = params[:search]["due_on(2i)"]
        date = "1"
        due_on = Date.parse(year + "-" + month + "-" + date)
        from = due_on.beginning_of_month
        to = due_on.end_of_month
        @invoices = @invoices.search_by_due_on_month(from, to)
      elsif params[:search]["due_on(1i)"].present?
        year = params[:search]["due_on(1i)"]
        month = "1"
        date = "1"
        due_on = Date.parse(year + "-" + month + "-" + date)
        from = due_on.beginning_of_year
        to = due_on.end_of_year
        @invoices = @invoices.search_by_due_on_year(from, to)
      elsif params[:search]["due_on(2i)"].present? || params[:search]["due_on(3i)"].present?
        @invoices = []
      end
      if params[:search][:subject].present?
        @invoices = @invoices.search_by_subject(params[:search][:subject])
      end
      if params[:search][:requestor_id].present?
        requestor_id = params[:search][:requestor_id]
        @invoices = @invoices.where(requestor_id: requestor_id)
      end
    end
  end
end
