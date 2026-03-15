require "rails_helper"

RSpec.describe Academico::Aluno::Entity do
  subject(:entity) do
    described_class.new(
      nome: "Felipe",
      email: "felipe@email.com",
      cpf: "12345678900",
    )
  end

  describe "#adicionar_telefone" do
    it "adiciona um telefone ao aluno" do
      entity.adicionar_telefone(ddd: "11", numero: "999999999")

      expect(entity.telefones.size).to eq(1)
    end

    it "permite até 2 telefones" do
      entity.adicionar_telefone(ddd: "11", numero: "999999999")
      entity.adicionar_telefone(ddd: "21", numero: "888888888")

      expect(entity.telefones.size).to eq(2)
    end

    it "não permite mais de 2 telefones" do
      entity.adicionar_telefone(ddd: "11", numero: "999999999")
      entity.adicionar_telefone(ddd: "21", numero: "888888888")

      expect {
        entity.adicionar_telefone(ddd: "31", numero: "777777777")
      }.to raise_error(StandardError)
    end
  end
end
