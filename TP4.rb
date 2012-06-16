#Tarea programada-ruby
#Lenguajes de programacion
#Melissa-Jean Carlo-Fernanda

# gems requeridad
require 'cgi'
require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'pp'
require "twitter"
require "oauth"

#clase menu
class Menu

  def crear_Menu
    puts "Bienvenid@ a JFM"
    puts "-----------------------Pasos-----------------------"
    puts "1. Digite el género o ubicación deseada"
    url = "http://bandcamp.com/tag/" + gets
	prueba = Recorrido.new('http://floriandroids.bandcamp.com/album/florian-droids')
	p prueba.top10(url)
    
  end
end
#--------------------------------TWITTER----------------------------------------------------------
#clase que realiza la autentificacion con Twitter
class Autentificacion
  def initialize()
  #La aplicación está registrada con los siguientes datos
  @token="TY7zz27iEF1CWY0sjK1cA"
  @secret ="WV0J7FynkbpDAgsqSEhFcGK4lNqm4BnKHTTZWVfCs"
  end

  #funcion que hace la conexion
  def conection

    #cliente para el oauth
    cliente=OAuth::Consumer.new(
      @token,
      @secret,
      {
        :site=>"http://twitter.com",
        :request_token_url=>"https://api.twitter.com/oauth/request_token",
        :access_token_url =>"https://api.twitter.com/oauth/access_token",
        :authorize_url    =>"https://api.twitter.com/oauth/authorize"
      }
    )
    #se solicita al api el token y el secret del usuario
    request_token = cliente.get_request_token
    token2 = request_token.token
    secret2 = request_token.secret
    #se abre el navegador predeterminado del sistema con la pagina de autorizacion
    direccion = cliente.authorize_url + "?oauth_token=" + token2
    puts "Abriendo en el navegador: "+direccion
    system('start '+direccion)
    #solicita el pin brindado por twitter
    print "Clic al link anterior e ingrese el pin que aparese en la pagina del Tweeter de su navegador:"
    pin = gets.chomp
	puts
    #se autentica al usuario con los datos brindados
    begin
      OAuth::RequestToken.new(cliente, token2, secret2)
      access_token=request_token.get_access_token(:oauth_verifier => pin)
      Twitter.configure do |config|
        config.consumer_key = @token
        config.consumer_secret = @secret
        config.oauth_token = access_token.token
        config.oauth_token_secret = access_token.secret
      end
      $client = Twitter::Client.new
      $client.verify_credentials
      puts "Autenticado Correctamente"

    rescue Twitter::Unauthorized
      puts "Error de Autorizacion"
    end
   end
end
#----------------------------------------------------BANDCAMP--------------------------------------------
#Recorre los tags selecionados y extrae los metadatos de las canciones
class Recorrido

	def initialize(url)
	  @url = url;
	  @hp = Hpricot(open(@url))
	end

	def recorre(link)
		array = []
		indice = 0
		cont = 0
		open(link) do |f|
		  f.each do |line|
			  if line == "popularity\n"
				indice = 1
			  end
			  if line == "                    .pager {\n"
				indice = 2
			  end
			  if indice == 1
				x = recorrido_line(line)
					if x != "vacio" and cont< 11
						array<<[x]
						cont = cont+1
					end
			  end 
		  end
		end
		return array
	end

	def recorrido_line(line)
		indice_1=0
		line.each_byte do |x|
			if  x == 97
				if indice_1 == 1
					return recorrido_byte(line)
					indice_1 = 0;
				end
			else
				indice_1 = 0
			end
			if x == 60
				indice_1 = 1
			end
		end
		return "vacio"
	end

	def recorrido_byte(line)
		indice_1 = 0
		indice_2 = 0
		link = ""
		line.each_byte do |x|
			if x == 34 and indice_1 == 1
				return link
			end
			if indice_1 == 1
				link=link.concat(x.chr)		
			end
			if x == 34
				indice_1 = 1
			end
			
		end
	end
		
	def costo(url)
		@link = url;
		@hp2 = Hpricot(open(@link))
		rating_text = (@hp2/"h4.compound-button").inner_text
		y="\n        \n          \n            Free Download\n          \n        \n        \n        \n    "
	   
		if rating_text== y
			return "Free"
		else	
			return"Pay"
		end
	end

	#AUTOR Y ALBUM

	def AutorAlbum(url)
	  url = url;
	  hp = Hpricot(open(url))
	  grupoAlbum = hp.at("meta[@name='title']")['content']
	  desglosa(grupoAlbum)
	  
	end

	def desglosa(grupoAlbum)
		grupoAlbum = grupoAlbum.split(', by ')
		grupoAlbum
	end

	#Definicio de datos  
	def datos(url)
		x = AutorAlbum(url)
		nueva_cancion = Cancion.new
		nueva_cancion.seturl(url)
		nueva_cancion.setalbum(x[0])
		nueva_cancion.setautor(x[1])
		nueva_cancion.setprecio(costo(url))
		
		tw = Tweet.new
		tw.tweetear(url, x[0], x[1], costo(url))
		
	
	end

#Presenta los 10 primeros resultados
	def top10(url)
		lista=recorre(url)
		for i in 1..10
			datos(lista[i][0])
		end
	end
end


#-------------------------------------------CLASE TWITTER---------------------------------------------

#clase tweet
class Tweet
  def tweetear(url, album, autor, precio)
  begin
    $client.update(url + "\n ALBUM: " + album + "\n AUTOR: " +  autor + "\n PRECIO: " +  precio)
  rescue Exception => e
    puts "Error: "+e.to_s
  end
end
end

#--------------------------------------------CANCION--------------------------------------------------
#Clase que crea el objeto
class Cancion
	attr_accessor:url
	attr_accessor:album
	attr_accessor:autor
	attr_accessor:precio
	
	def seturl(nuevo_url)
		url = nuevo_url
		puts "url -> "+ url
	end
	
	def setalbum(nuevo_album)
		album = nuevo_album
		puts "Album -> "+ album
	end
	
	def setautor(nuevo_autor)
		autor = nuevo_autor
		puts "Autor -> "+ autor
	end
	
	def setprecio(nuevo_precio)
		precio = nuevo_precio
		puts "Precio -> "+ precio
	end
end
	
#-----------------------------------------------------MAIN---------------------------------------------	
#funcion inicial para ejecutar el programa
def ini
  begin
    i=Autentificacion.new()
    i.conection
    Menu.new.crear_Menu
  rescue => e
    puts "Ocurrio un problema por favor vuelva a intertar la autentificacion"
    ini
  end
end

ini
