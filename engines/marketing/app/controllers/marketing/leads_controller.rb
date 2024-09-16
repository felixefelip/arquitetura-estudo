class Marketing::LeadsController < ApplicationController
  def create
    ::Marketing::Lead::Generate.call(
      full_name: params["nome"],
      email: params["email"],
    )

    render json: {}, status: :created
  end
end
