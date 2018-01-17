class DashboardController < ApplicationController
  def show
    page = params[:page].present? ? params[:page].to_i : 1
    @calls = Call.all.paginate(per_page: 30, page: page)
  end
end
