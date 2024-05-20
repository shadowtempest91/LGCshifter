# Copyright 2024 Alex Isabelle

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "tty-prompt"
require "nokogiri"

# Oggetto che contiene un elenco di tutti i file gli LGC3 attualmente presenti della directory
# Viene creata in automatico a inizio esecuzione del programma
class Directory

	def initialize
	
		# Crea una variabile che conterrà l'elenco dei file
		@files = Array.new
		
		# Ci mette dentro tutti i file di LGC3
		Dir.entries("./").each {
			|file|
			if file.end_with?(".xlgc")
				@files << file
			end
		}
		
		# Riordina l'array
		@files.sort!
	end
	
	# Metodo che restituisce la lista dei file presenti in directory
	def return_list
		return @files
	end

end

# Oggetto che conterrà i file che saranno oggetto della trasformazione
class LGC3_file

	def initialize (path)
		@name = path
		@code = File.open(path, "r")
		@code_nok = Nokogiri::XML(File.open(path, "r"))
	end
	
	def shift
		@shift = Hash.new
		
		# Guarda i numeri dei paragrafi
		last_num = 0
		drift = 0
		@code_nok.xpath("//entity[@type=\"chapter\"]/@name").each {
			|num_nok|
			num = num_nok.to_s
			
			# Se trova un buco...
			if num.to_i != last_num + 1
				
				# ...aggiorna il drift
				drift += num.to_i - last_num - 1		
			end
			
			# Segna la numerazione aggiornata di ogni singolo paragrafo in un hash
			@shift[num.to_sym] = num.to_i - drift
			last_num = num.to_i
		}
		
		# Crea una variabile che conterrà il codice aggiornato. Le modifiche verranno fatte mano a mano che il codice verrà copiato
		@code_shifted = Array.new
		
		# Crea una variabile che conterrà la singola riga di codice. Le modifiche verranno svolte su di essa prima di copiarla in @code_temp
		string_temp = String.new
		
		# Comincia a copiare una riga alla volta
		for cont in 0..@code.readlines.length-1
			@code.rewind
			string_temp = @code.readlines[cont]
			
			# Attua le sostituzioni, che non si invalideranno a vicenda perchè sono tutte in ordine progressivo quindi i numeri non si "incroceranno"
			@shift.each_pair {
				|from, to|
				string_temp.gsub!("name=\"" + from.to_s + "\" type=\"chapter\"", "name=\"" + to.to_s + "\" type=\"chapter\"")
				string_temp.gsub!("[" + from.to_s + "]", "[" + to.to_s + "]")
			}
		
			# Copia la riga modificata nel documento
			@code_shifted << string_temp
		end
	end
	
	def return_name
		return @name
	end
	
	def return_code_shifted
		return @code_shifted
	end
end

# COSTANTI
VERSION = "1.0"

# Inizializzazione
$prompt = TTY::Prompt.new
directory = Directory.new

# Nucleo del programma
$prompt.say("\nLGC3shifter by Alex Isabelle, versione " + VERSION + ".")
$prompt.say("Licenza: GPL-3.0")
$prompt.warn("Il programma creerà un nuovo file che sarà identico a quello originale, ma rinumerato in maniera tale da eliminare i paragrafi inesistenti.\n")
file_1 = LGC3_file.new($prompt.select("Seleziona il file che vuoi rinumerare:", directory.return_list))
file_1.shift
file_2_name = file_1.return_name.chop.chop.chop.chop.chop + "_shifted.xlgc"
file_2 = File.new(file_2_name, mode="w+")
file_1.return_code_shifted.each {
	|riga|
	file_2.puts riga
}
