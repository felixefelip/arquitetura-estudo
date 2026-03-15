# rbs_inline: enabled

module Finance
  module Client
    class Enroll
      def initialize(client:, card:)
        self.client = client
        self.card = card
      end

      def call
        puts "Processando pagamento de #{client.full_name}"

        sleep 3 if ENV["RAILS_ENV"] != "test"

        card.client = client

        ApplicationRecord.transaction do
          client.save!
          card.save!
        end

        send_event_client_enrolled
      end

      private

      attr_accessor :client
      attr_accessor :card

      def send_event_client_enrolled
        # Publicar evento usando ActiveSupport::Notifications
        payload = {
          client_payload: JSON.parse(client.to_json).deep_symbolize_keys,
          momento: DateTime.current,
          name: "finance_client_enrolled",
        }

        # Ao invés de usar um bloco vazio, podemos fazer algo no bloco
        ActiveSupport::Notifications.instrument("finance_client_enrolled", payload) do
          Rails.logger.info "Evento finance_client_enrolled publicado para o cliente #{client.full_name}"
        end
      end
    end
  end
end
