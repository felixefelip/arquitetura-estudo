# rbs_inline: enabled

class Finance::ClientsController < ApplicationController
  # @rbs () -> void
  def create
    client = build_client
    card = build_card

    ::Finance::Client::Enroll.new(
      client: client, card: card,
      publicador_de_evento: $publicador,
    ).call

    render :json, status: :created
  end

  private

  # @rbs () -> Finance::Client::Entity
  def build_client
    Finance::Client::Entity.new(
      full_name: params[:cardOwnerFullName], email: params[:email],
      document: params[:clientDocument]
    )
  end

  # @rbs () -> Finance::Card::Entity
  def build_card
    Finance::Card::Entity.new(
      number: params[:cardNumber],
      owner_full_name: params[:cardOwnerFullName],
      month_expiration: params[:cardExpirationMonth],
      year_expiration: params[:cardExpirationYear],
      security_code: params[:cardSecurityCode],
    )
  end
end
