=begin

require 'benchmark'
require 'nokogiri'
require 'open-uri'
require 'active_support/core_ext/hash'

def get_translations(headword)
  sense = headword["entry"]["sense"]
  quote = []
  max_trans = 1
  count = 0

  if sense.is_a? Hash
    cit = sense["cit"]
    if cit.is_a? Hash
      return [cit["quote"]]
    else
      cit.each { |cit|
        quote << cit["quote"]
        count += 1
          return quote if count >= max_trans
      }      
    end
  else
    sense.each { |sense|
      cit = sense["cit"]
      if cit.is_a? Hash
        quote << cit["quote"]
        count += 1
      else
        cit.each { |cit|
          quote << cit["quote"]
          count += 1
            return quote if count >= max_trans
        }
      end
        return quote if count >= max_trans
    }
      return quote
  end
end

def transcription(headword)
  a = ""
  h = headword.downcase
  skip = 0
  
  for i in 0..h.length
  
    if skip > 0
      skip -= 1
      next
    end
  
    case h[i]
      when "y"
        a << "i"
      when "v"
        a << "b"
      when "w"
        a << "u"
      when "ñ"
        a << "ni"
      when "x"
        a << "ks"
      when "h"
      when "q"
        case h[i+1]
          when "u"
            a << "k"
            skip += 1
        else
          a << h[i]
        end
      when "r"
        case h[i+1]
          when "r"
            a << "r"
            skip += 1
        else
          a << h[i]
        end
      when "l"
        case h[i+1]
          when "l"
            a << "i"
            skip += 1
        else
          a << h[i]
        end
      when "c"
        skip += 1      
        case h[i+1]
          when "a"
            a << "ka"
          when "h"
            a << "ch"
          when "o"
            a << "ko"
          when "u"
            a << "ku"
          when "i"
            a << "zi"
          when "e"
            a << "ze"       
        else
          a << h[i]
          skip -= 1
        end
      when "g"
        skip += 1
        case h[i+1]
          when "e"
            a << "je"
          when "i"
            a << "ji"
          when "u"
            skip += 1
            case h[i+2]
              when "e"
                a << "ge"
              when "i"
                a << "gi"
            else
              skip -= 1
              a << "gu"
            end
        else
          skip -= 1
          a << h[i]
        end
    else
      a << "#{h[i]}"
    end
  
  end
    return a

end

puts Benchmark.measure {

batch_size = 300
count = 0
items = []
doc = File.read("db/temp_file.xml")
doc1 = File.read("db/temp_file1.xml")
doc = Nokogiri::XML.parse(doc1.to_s)

doc.xpath("//entry").each do |element|
	item = Hash.from_xml(element.to_s)
  items << { headword:item["entry"]["form"]["orth"],transcription:transcription(item["entry"]["form"]["orth"]),translation:get_translations(item).first }
	count += 1

	if count == batch_size
		Spanish.import items, validate: false, :batch_size => batch_size
		count = 0
		items = []
	end

end

if !items.empty?
	Spanish.import items, validate: false, :batch_size => batch_size
end

}

=end

#=begin

require 'benchmark'
require 'nokogiri'
require 'open-uri'
require 'active_support/core_ext/hash'
require 'thread'

def remove_accent(word)
  word.gsub(/[àáâèéêìíîòóôùúû¿]/, 'à' => 'a', 'á' => 'a', 'â' => 'a', 'è' => 'e', 'é' => 'e', 'ê' => 'e', 'ì' => 'i', 'í' => 'i', 'î' => 'i', 'ò' => 'o', 'ó' => 'o', 'ô' => 'o', 'ù' => 'u', 'ú' => 'u', 'û' => 'u', '¿' => '')  
end

def get_translations(headword, max_trans)
  sense = headword["entry"]["sense"]
  quote = []
  count = 0

  if sense.is_a? Hash
    cit = sense["cit"]
    if cit.is_a? Hash
      return [cit["quote"]]
    else
      cit.each { |cit|
        quote << cit["quote"]
        count += 1
          return quote if count >= max_trans
      }      
    end
  else
    sense.each { |sense|
      cit = sense["cit"]
      if cit.is_a? Hash
        quote << cit["quote"]
        count += 1
      else
        cit.each { |cit|
          quote << cit["quote"]
          count += 1
            return quote if count >= max_trans
        }
      end
        return quote if count >= max_trans
    }
  end
    return quote  
end

def transcription(headword)
  a = ""  
  h = remove_accent(headword).downcase
  skip = 0
  
  for i in 0..h.length
  
    if skip > 0
      skip -= 1
      next
    end
  
    case h[i]
      when "y"
        a << "i"
      when "v"
        a << "b"
      when "w"
        a << "u"
      when "ñ"
        a << "ni"
      when "x"
        a << "ks"
      when "h"
      when "q"
        case h[i+1]
          when "u"
            a << "k"
            skip += 1
        else
          a << h[i]
        end
      when "r"
        case h[i+1]
          when "r"
            a << "r"
            skip += 1
        else
          a << h[i]
        end
      when "l"
        case h[i+1]
          when "l"
            a << "i"
            skip += 1
        else
          a << h[i]
        end
      when "c"
        skip += 1      
        case h[i+1]
          when "a"
            a << "ka"
          when "h"
            a << "ch"
          when "o"
            a << "ko"
          when "u"
            a << "ku"
          when "i"
            a << "zi"
          when "e"
            a << "ze"       
        else
          a << h[i]
          skip -= 1
        end
      when "g"
        skip += 1
        case h[i+1]
          when "e"
            a << "je"
          when "i"
            a << "ji"
          when "u"
            skip += 1
            case h[i+2]
              when "e"
                a << "ge"
              when "i"
                a << "gi"
            else
              skip -= 1
              a << "gu"
            end
        else
          skip -= 1
          a << h[i]
        end
    else
      a << "#{h[i]}"
    end
  
  end
    return a

end


puts Benchmark.measure {

doc = File.read("db/temp_file.xml")
doc1 = File.read("db/temp_file1.xml")
doc1 = File.read("db/spanish_english.xml")
doc = Nokogiri::XML.parse(doc1.to_s)

mutex = Mutex.new
con_var = ConditionVariable.new
items = []
count = 0
batch_size = 300

db_import = Thread.new {
  mutex.synchronize {
		loop do
      con_var.wait(mutex)
      import_items = items
      con_var.signal
			Spanish.import import_items, validate: false, :batch_size => batch_size
		end
  }
}

file_import = Thread.new {
  mutex.synchronize {
		doc.xpath("//entry").each do |element|
			item = Hash.from_xml(element.to_s)
      headword = item["entry"]["form"]["orth"]
      translation = get_translations(item,4).join(",")
			items << { headword:remove_accent(headword),transcription:transcription(headword),translation:translation }
			count += 1

			if count == batch_size
	  		while db_import.status == "run" do
					sleep(0.0001)
	 			end
		   	con_var.signal        
	   	 	con_var.wait(mutex)
	   	 	items = []
	   	 	count = 0
	   	end
	  end

	  if count > 0		  	
	 		con_var.signal
	  	con_var.wait(mutex)
	  end

	 	while db_import.status == "run" do
 			sleep(0.0001)
	 	end
	  db_import.kill
	  file_import.kill
  }
}

db_import.join
file_import.join

}

#=end