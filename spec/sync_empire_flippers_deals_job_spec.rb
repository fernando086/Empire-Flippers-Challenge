# Carga las configuraciones del entorno de prueba de Rails
require 'rails_helper'
# Carga la librería WebMock para simular interceptaciones de red
require 'webmock/rspec'

# Inicia la suite de RSpec apuntando a tu clase y estableciendo que el contexto a probar es un Job (`type: :job`)
RSpec.describe SyncEmpireFlippersDealsJob, type: :job do
  
  # 'let' es un bloque perezoso de RSpec que define variables (métodos) de estado, instanciándose solo bajo demanda por prueba
  let(:listing_number) { '12345' }
  # Aquí simulamos textualmente (como String vía '.to_json') lo que Empire Flippers retornaría en producción
  let(:api_response) do
    {
      data: {
        listings: [
          { listing_number: listing_number, listing_price: 150000.0, summary: 'A great SaaS business' }
        ]
      }
    }.to_json
  end

  # 'before' es un "Hook" que ejecuta las instrucciones pre-requisitas que necesita la prueba para funcionar.
  before do
    allow(ENV).to receive(:fetch).with('HUBSPOT_API_KEY').and_return('fake_key')
    
    # CORRECCIÓN: Usamos Expresiones Regulares (%r{...}) para decirle a WebMock que intercepte 
    # cualquier llamada a la URL sin importar la página en la que esté iterando.
    stub_request(:get, %r{https://api.empireflippers.com/api/v1/listings/list\?listing_status=For%20Sale})
      .to_return(status: 200, body: api_response, headers: { 'Content-Type' => 'application/json' })
  end

  # Describe test cases donde se evalúa el comportamiento contra la instancia real del servidor de HubSpot
  describe 'HubSpot interaction and DB saving' do
    # 'instance_double' crea copias huecas exactas de objetos asegurando que solo los métodos existentes operen sobre ellos
    let(:hubspot_client_mock) { instance_double(Hubspot::Client) }
    let(:crm_mock) { double('crm') }
    let(:deals_mock) { double('deals') }
    let(:basic_api_mock) { double('basic_api') }

    before do
      # Forzamos la cadena anidada de la Gema de HubSpot a siempre encaminarse hacia nuestros mocks (Simulacros) de prueba
      allow(Hubspot::Client).to receive(:new).and_return(hubspot_client_mock)
      allow(hubspot_client_mock).to receive(:crm).and_return(crm_mock)
      allow(crm_mock).to receive(:deals).and_return(deals_mock)
      allow(deals_mock).to receive(:basic_api).and_return(basic_api_mock)
    end

    # 'it' define una afirmación individual conteniendo la fase de ejecución de algo y qué aserción/expectativa tenemos del resultado
    it 'creates a deal in HubSpot and saves a Listing model locally' do
      # Definimos una Expecatativa Comportamental donde 'basic_api_mock' tiene el imperativo estricto de recibir una invocación hacia el método '.create'
      expect(basic_api_mock).to receive(:create).once

      # Invocamos la clase del Job de nuestra app llamando el objeto .new y la ejecución de '.perform' insertado en una sintaxis de evaluación especial `{...}`
      # 'change().by(1)' cuenta que haya una transaccion correcta en base de datos.
      expect {
        SyncEmpireFlippersDealsJob.new.perform
      }.to change(Listing, :count).by(1)
    end

    it 'does NOT create a HubSpot deal if listing already exists' do
      # Almacenamos artificialmente en la prueba local previa, un Listing con el mismo index
      Listing.create!(listing_number: listing_number, price: 150000, status: 'For Sale')

      # Definimos que 'NOT_TO receive' debe verificarse asertivamente para la simulación del API ya que el loop del código usa 'next if...'
      expect(basic_api_mock).not_to receive(:create)

      # Al disparar perform, no debe haber ningún cambio en la cuenta
      expect {
        SyncEmpireFlippersDealsJob.new.perform
      }.to change(Listing, :count).by(0)
    end
  end
end
