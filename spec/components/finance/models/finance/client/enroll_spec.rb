require "rails_helper"

RSpec.describe Finance::Client::Enroll do
  describe "#call" do
    it "cria um aluno", :aggregate_failures do
      Marketing::Lead::Generate.call(full_name: "Felipe Feliz", email: "felipe@email.com")

      client = Finance::Client::Entity.new(
        full_name: "Felipe Feliz",
        email: "felipe@email.com",
        document: "123456",
      )

      card = Finance::Card::Entity.new(
        number: "1140028922",
        owner_full_name: "Felipe",
        month_expiration: "08",
        year_expiration: "2030",
        security_code: "123",
        client: client,
      )

      # expect(ActiveSupport::Notifications).to(receive(:instrument).with(
      #   "finance_client_enrolled",
      #   hash_including(:client_payload, :momento, :name),
      # ).once)

      described_class.new(
        client: client,
        card: card,
      ).call

      client_finance = Finance::Client::Entity.find_by!(email: "felipe@email.com")
      aluno_academico = Academico::Aluno::Repositories::ActiveRecord::Impl.new.buscar_por_email(client_finance.email)

      expect(aluno_academico).to be_present

      expect(Finance::Client::Entity.count).to eq 1
      expect(Academico::Aluno::Repositories::ActiveRecord::Impl.new.buscar_todos.count).to eq 1
      expect(Marketing::Lead::Entity.find_by!(email: client_finance.email)).to be_customer
    end
  end
end
