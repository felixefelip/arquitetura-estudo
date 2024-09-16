module Finance
  module Client
    class Enroll
      def initialize(full_name:, email:, document:, number:, owner_full_name:,
                     month_expiration:, year_expiration:, security_code:, publicador_de_evento:)
        self.full_name = full_name
        self.email = email
        self.document = document
        self.number = number
        self.owner_full_name = owner_full_name
        self.month_expiration = month_expiration
        self.year_expiration = year_expiration
        self.security_code = security_code
        self.publicador_de_evento = publicador_de_evento
      end

      def self.call(full_name:, email:, document:, number:,
                    owner_full_name:, month_expiration:, year_expiration:,
                    security_code:, publicador_de_evento:)
        new(full_name:, email:, document:, number:,
            owner_full_name:, month_expiration:, year_expiration:,
            security_code:, publicador_de_evento:).call
      end

      def call
        puts "Processando pagamento de #{owner_full_name}"

        sleep 3 if ENV["RAILS_ENV"] != "test"

        client = Entity.create!(full_name:, email:, document:)
        client.cards.create!(number:, owner_full_name:,
                             month_expiration:, year_expiration:, security_code:)

        # enviar mensagem para fila client_enrolled
        evento = Enrolled.new(client_payload: JSON.parse(client.to_json))
        publicador_de_evento.publicar(evento:)
      end

      private

      attr_accessor :full_name, :email, :document, :number,
                    :owner_full_name, :month_expiration, :year_expiration,
                    :security_code, :publicador_de_evento
    end
  end
end
