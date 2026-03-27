# Requerimos librerías estándar de Ruby para hacer peticiones HTTP y manipular JSON
require 'net/http'
require 'json'

# Definimos que la clase (Class) de nuestro trabajo es SyncEmpireFlippersDealsJob
class SyncEmpireFlippersDealsJob
  # 'include' añade los métodos del módulo Sidekiq::Job a nuestra clase, otorgándole súper poderes de background job
  include Sidekiq::Job

  # 'def' define un método. Sidekiq siempre busca un método llamado 'perform' para ejecutar el trabajo
  def perform

    # === 1. CONFIGURACIÓN DE HUBSPOT ===
    
    # 'ENV' es un objeto global tipo Hash en Ruby que lee variables de entorno del sistema operativo.
    # 'fetch' busca la llave y, a diferencia de ENV['KEY'], ¡lanza un error ("KeyError") si no existe!, evitando que el código falle silenciosamente por temas de seguridad.
    hubspot_api_key = ENV.fetch('HUBSPOT_API_KEY')
    
    # Instanciamos la clase 'Client' del namespace 'Hubspot' pasándole un hash de argumentos con el access_token.
    # Esta es la sintaxis requerida para la V20+ del cliente.
    hubspot_client = Hubspot::Client.new(access_token: hubspot_api_key)


    # === 2. CONSUMIR API DE EMPIRE FLIPPERS (CON PAGINACIÓN) ===
    
    page = 1
    # Usamos un ciclo infinito 'loop' que romperemos internamente cuando se cumplan las condiciones ('break').
    loop do
      
      # Agregamos los parámetros 'limit' y 'page' para paginar.
      # Eliminamos el filtro '?status=For%20Sale' para traer absolutamente todos los listings (Sold, For Sale, etc).
      uri = URI("https://api.empireflippers.com/api/v1/listings/list?listing_status=For%20Sale&limit=100&page=#{page}")
      
      # Invocamos el método de clase 'get' pasándole nuestro objeto URI; retorna un String con la respuesta HTTP.
      response_body = Net::HTTP.get(uri)
      
      # Usamos 'parse' de la clase JSON para convertir el String text de la respuesta neta en un Hash nativo de Ruby.
      data = JSON.parse(response_body)
      
      # Navegamos el Hash con 'dig', a las llaves ['data']['listings'].
      # El operador '|| []' (OR lógico) protege nuestro código: si es nil, asignará un arreglo vacío para prevenir errores.
      listings = data.dig('data', 'listings') || []
      
      # Rompemos el ciclo infinito automáticamente cuando no vengan más listings en la página actual.
      break if listings.empty?

      # === 3. ITERAR RESULTADOS Y CREAR DEALS ===
      
      # El método 'each' itera sobre arreglos. El código entre 'do' y 'end' es un bloque de código (Block).
      listings.each do |listing_data|
        
        # Extraemos el valor de la propiedad, y el método '.to_s' convierte la variable a String (por precaución).
        listing_number = listing_data['listing_number'].to_s
        
        # '.find_by' busca el primer registro local que cumpla la condición.
        # La palabra reservada 'next' interrumpe el bloque actual y salta instantáneamente al siguiente elemento del ciclo 'each' si la condición posterior al 'if' se cumple.
        next if Listing.find_by(listing_number: listing_number)

        price = listing_data['listing_price']
        summary = listing_data['summary']

        # ==== NUEVO ====
        # En lugar de colocar todos como 'For Sale', extraemos el estatus real de la API ('Sold', 'For Sale', etc).
        status = listing_data['listing_status'] || 'Unknown'

        # '30.days.from_now' (método mágico de Rails en ActiveSupport) avanza 30 días exactos en el reloj.
        # '.iso8601' formatea este objeto de tiempo al estándar de fechas requerido usualmente por las API modernas.
        close_date = 30.days.from_now.iso8601

        # Definimos un Hash (Dicc/Mapa en otros lenguajes) usando sintaxis hash rockets ('=>') para declarar las llaves como String, las cuales espera HubSpot.
        deal_properties = {
          # La convención "\#{variable}" interpola código Ruby (inyecta el valor en tiempo de ejecución) dentro de un String con dobles comillas.
          "dealname" => "Listing #{listing_number}",
          "amount" => price.to_s,
          "closedate" => close_date,
          "description" => summary
        }

        # V20+: Declaramos un objeto 'Input' en formato de Hash (nativo de Ruby) para evitar NameErrors.
        # Usar un hash es interpretado directamente y de forma segura por el cliente de HubSpot.
        body = { properties: deal_properties }

        # 'begin' inicia una zona de control estructurada para el manejo de excepciones (try / catch).
        begin
          # En la V20+ de HubSpot, el parámetro nombrado estricto es 'simple_public_object_input_for_create'
          hubspot_client.crm.deals.basic_api.create(simple_public_object_input_for_create: body)
          
          Listing.create!(
            listing_number: listing_number,
            price: price,
            status: status
          )
        rescue Hubspot::Crm::Deals::ApiError => e
          Rails.logger.error("Error crítico comunicando con HubSpot para Listing #{listing_number}: #{e.message}")
        end

      # 'end' indica la terminación lógica de las instrucciones dentro de la iteración 'each'.
      end
      
      # Validamos si ya llegamos a visualizar la última página reportada por el sub-objeto de EF.
      total_pages = data.dig('data', 'pages') || 1
      break if page >= total_pages
      
      # Sumamos 1 a la variable page para avanzar a la siguiente página web en el loop.
      page += 1
      
    # 'end' cierra la fase/bloque de la estructura de ciclo 'loop'
    end
    
  # 'end' cierra la fase/bloque de la declaración de la función 'perform'.
  end
  
# 'end' cierra finalmente la definición de nuestra clase de objeto rubícola.
end
