#!/usr/bin/ruby -w
# encoding: UTF-8

require "dbi" #for DB access
require "unicode" #for downcasing not ASCII characters

def remove_accent(word)
  word.gsub(/[čšéîá]/, 'á' => 'a', 'č' => 'c', 'š' => 's', 'é' => 'e', 'î' => 'i') 
end

def transcription(headword)
  a = ""  
  h = Unicode.downcase(headword)
  h = remove_accent(h)
  skip = 0
  
  for i in 0..h.length
  
    if skip > 0
      skip -= 1
      next
    end
  
    case h[i]

      when "ö"
        a << "o"
      when "ü"
        a << "u"
      when "j"
        a << "i"
      when "k"
        a << "k"
      when "ß"
        a << "s"
      when "u"
        a << "u"
      when "v"
        a << "f"
      when "w"
        a << "v"
      when "x"
        a << "ks"
      when "y"
        a << "i"
      when "z"
        a << "ts"
      when "d"
          a << "d"
      when "g"
          a << "g"

      when "h"
        case h[i+1]
          when "y" 
            if i == 0
              a << "i"
              skip += 1          
            else
              a << "hy"
              skip += 1
            end
        else
          if i == 0
            a << "j"          
          end
        end

      when "ä"
        case h[i+1]
          when "u"
            a << "au"
            skip += 1
        else
          a << "e"
        end

      when "r"
        case h[i+1]
          when "r"
            a << "r"
            skip += 1
        else
          a << "r"
        end

      when "i"
        case h[i+1]
          when "e"
            a << "i"
            skip += 1
        else
          a << "i"
        end

      when "o"
        case h[i+1]
          when "o"
            a << "o"
            skip += 1
        else
          a << "o"
        end

      when "q"
        case h[i+1]
          when "u"
            a << "ku"
            skip += 1
        end

      when "l"
        case h[i+1]
          when "l"
            a << "l"
            skip += 1
        else
          a << "l"
        end

      when "n"
        case h[i+1]
          when "n"
            a << "n"
            skip += 1
        else
          a << "n"
        end

      when "m"
        case h[i+1]
          when "m"
            a << "m"
            skip += 1
        else
          a << "m"
        end

      when "f"
        case h[i+1]
          when "f"
            a << "f"
            skip += 1
        else
          a << "f"
        end

      when "b"
        case h[i+1]
          when "b"
            a << "b"
            skip += 1
        else
          a << "b"
        end

      when "c"
        case h[i+1]
          when "h"
            a << "j"
            skip += 1
          when "k"
            a << "k"
            skip += 1
        else
          a << "k"
        end

      when "a"
        case h[i+1]
          when "a"
            a << "a"
            skip += 1
        else
          a << "a"
        end

      when "t"
        case h[i+1]
          when "t"
            a << "t"
            skip += 1
          when "z"
            a << "ts"
            skip += 1
        else
          a << "t"
        end

      when "p"
        case h[i+1]
          when "p"
            a << "p"
            skip += 1
          when "h"
            a << "f"
            skip += 1
          when "f"
            if i == 0
              a << "f"
              skip += 1
            else
              a << "pf"
              skip += 1
            end
        else
          a << "p"
        end

      when "e"
        case h[i+1]
          when "u"
            a << "oi"
            skip += 1
          when "i"
            a << "ai"
            skip += 1
          when "e"
            a << "e"
            skip += 1
        else
          a << "e"
        end

      when "s"
        skip += 1
        case h[i+1]
          when "t"
            if i == 0
              a << "sht"
            else
              a << "st"
            end
          when "p"
            if i == 0
              a << "shp"
            else              
              a << "sp"
            end
          when "c"
            skip += 1
            case h[i+2]
              when "h"
                a << "sh"
            else
              skip -= 1
              a << "sc"
            end
          when "s"
            if h[i+2] == "c" && h[i+3] == "h"
              a << "s"
              skip -= 1
            else
              a << "s"
            end
        else
          skip -= 1
          a << "s"
        end

      when "e"
        case h[i+1]
          when "u"
            a << "oi"
            skip += 1
          when "i"
            a << "ai"
            skip += 1
          when "e"
            a << "e"
            skip += 1
        else
          a << "e"
        end

    else
      a << "#{h[i]}"
    end
  end
    return a
end

max_rows = 100

begin
  database = DBI.connect("DBI:Mysql:metaforat_development:localhost", "metaforat", "password")
  data = database.prepare("SELECT expression_id, spelling FROM uw_expression WHERE language_id = ? and remove_transaction_id is NULL ORDER BY spelling ASC")
  update = database.prepare("UPDATE uw_expression SET transcription = ? WHERE expression_id = ?")
  data.execute(101)
  rows = data.fetch_many(max_rows)
  #file = File.open("../metaforat/german_transcriptions.txt","w")
  
  loop do
     rows = data.fetch_many(max_rows)
     rows.each do |row|
       row[1].force_encoding("utf-8").encode("utf-8") #ruby is not always able to detect encoding correctly
       #puts "#{row[0]} - #{remove_accent(row[0])}"
       #puts remove_accent(row[0])
       #file << "#{Unicode.downcase(remove_accent(row[0]))} - [#{transcription(row[0])}]\n"
       update.execute(transcription(row[1]), row[0])
     end
     break if rows.count < max_rows      
  end

  #file.close
rescue DBI::DatabaseError => e
   puts "An error occurred"
   puts "Error code:    #{e.err}"
   puts "Error message: #{e.errstr}"
ensure
   database.disconnect if database
end