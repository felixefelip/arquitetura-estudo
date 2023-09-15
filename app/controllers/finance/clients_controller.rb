class Finance::ClientsController < ApplicationController
  def create
    ::Finance::Client::Enroll.new.call(
      full_name: params[:full_name],
      email: params[:email],
      document: params[:document],
      number: params[:number],
      owner_full_name: params[:owner_full_name],
      month_expiration: params[:month_expiration],
      year_expiration: params[:year_expiration],
      security_code: params[:security_code],
    )
  end
end
