class Finance::ClientsController < ApplicationController
  def create
    ::Finance::Client::Enroll.call(
      full_name: params[:cardOwnerFullName],
      email: params[:email],
      document: params[:clientDocument],
      number: params[:cardNumber],
      owner_full_name: params[:cardOwnerFullName],
      month_expiration: params[:cardExpirationMonth],
      year_expiration: params[:cardExpirationYear],
      security_code: params[:cardSecurityCode],
      publicador_de_evento: $publicador,
    )

    render json: {}, status: :created
  end
end
