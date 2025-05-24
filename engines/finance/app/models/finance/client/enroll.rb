module Finance
  module Client
    class Enroll
      def initialize(client:, card:, publicador_de_evento:)
        self.client = client
        self.card = card
        self.publicador_de_evento = publicador_de_evento
      end

      def call
        puts "Processando pagamento de #{client.full_name}"

        sleep 3 if ENV["RAILS_ENV"] != "test"

        ApplicationRecord.transaction do
          client.save!
          card.save!
        end

        # enviar mensagem para fila client_enrolled
        # ActiveSupport::Notifications.instrument(
        #   :item_pedido_alterado,
        #   payload: { client_payload: JSON.parse(client.to_json) },
        # ) {}

        evento = Enrolled.new(client_payload: JSON.parse(client.to_json))
        publicador_de_evento.publicar(evento:)
      end

      private

      attr_accessor :client, :card, :publicador_de_evento
    end
  end
end
