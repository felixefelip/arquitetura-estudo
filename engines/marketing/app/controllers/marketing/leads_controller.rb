# rbs_inline: enabled

class Marketing::LeadsController < ApplicationController
  #: -> void
  def new
    plano = build_plans
    render Marketing::Leads::NewComponent.new(plano: plano)
  end

  #: -> void
  def create
    ::Marketing::Lead::Generate.call(
      full_name: params["nome"],
      email: params["email"],
    )

    redirect_to sucesso_marketing_leads_path, notice: "Compra realizada com sucesso!"
  end

  #: -> void
  def sucesso
    render Marketing::Leads::SucessoComponent.new
  end

  private

  #: -> Hash[Symbol, untyped]
  def build_plans
    {
      nome: "Plano mega power",
      valor: "R$ 123,45",
      total_cursos: 1234,
      beneficios: [
        "Estude por 1 ano",
        "Certificado de participação",
        "Apps para Android e iOS",
      ],
    }
  end
end
