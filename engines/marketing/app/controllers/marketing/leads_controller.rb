# rbs_inline: enabled

class Marketing::LeadsController < ApplicationController
  # @rbs -> void
  def new
    plano = {
      nome: "Plano mega power",
      valor: "R$ 123,45",
      total_cursos: 1234,
      beneficios: [
        "Estude por 1 ano",
        "Certificado de participação",
        "Apps para Android e iOS",
      ],
    }

    render Marketing::Leads::NewComponent.new(plano: plano)
  end

  # @rbs -> void
  def create
    ::Marketing::Lead::Generate.call(
      full_name: params["nome"],
      email: params["email"],
    )

    redirect_to sucesso_marketing_leads_path, notice: "Compra realizada com sucesso!"
  end

  # @rbs -> void
  def sucesso
    render Marketing::Leads::SucessoComponent.new
  end
end
