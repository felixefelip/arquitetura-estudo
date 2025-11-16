# rbs_inline: enabled

class Marketing::LeadsController < ApplicationController
  # @rbs -> void
  def create
    ::Marketing::Lead::Generate.call(
      full_name: params["nome"],
      email: params["email"],
    )

    render :json, status: :created
  end
end
