# rbs_inline: enabled

class Marketing::LeadsController < ApplicationController
  def new
    lead = Marketing::Lead::Entity.new

    plano = build_plans
    render Marketing::Leads::NewComponent.new(lead: lead, plano: plano)
  end

  def create
    lead = ::Marketing::Lead::Generate.new(
      full_name: params[:marketing_lead_entity][:full_name],
      email: params[:marketing_lead_entity][:email],
    ).call

    plano = build_plans
    render Marketing::Leads::PaymentStepComponent.new(lead: lead, plano: plano)
  end

  def sucesso
    render Marketing::Leads::SucessoComponent.new
  end

  private

  attr_accessor :lead

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
