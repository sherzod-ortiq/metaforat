#!/usr/bin/ruby -w
# encoding: UTF-8

require "dbi" #for DB access
require "unicode" #for downcasing not ASCII characters

def remove_accent(word)
  word.gsub(/[άόϊίέώήϋύ]/, 'ά' => 'α', 'ἄ' => 'α', 'ό' => 'ο', 'ϊ' => 'ι', 'ί' => 'ι', 'έ' => 'ε', 'ώ' => 'ω', 'ή' => 'η', 'ϋ' => 'υ', 'ύ' => 'υ') 
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
      when "'" 
      when "’"
      when "β"
        a << "b"
      when "δ"
        a << "d"
      when "ζ"
        a << "s"
      when "θ"
        a << "z"
      when "κ"
        a << "k"
      when "φ"
        a << "f"
      when "χ"
        a << "j"
      when "ω"
        a << "o"
      when "ς"
        a << "s"
      when "ξ"
        a << "ks"
      when "ψ"
        a << "ps"


      when "π"
        case h[i+1]
          when "π"
            a << "p"
            skip += 1
        else
          a << "p"
        end


      when "λ"
        case h[i+1]
          when "λ"
            a << "l"
            skip += 1
        else
          a << "l"
        end

      when "ρ"
        case h[i+1]
          when "ρ"
            a << "r"
            skip += 1
        else
          a << "r"
        end

      when "α"
        case h[i+1]
          when "υ"
            a << "af"
            skip += 1
          when "ι"
            a << "e"
            skip += 1
        else
          a << "a"
        end

      when "ε"
        case h[i+1]
          when "υ"
            case h[i+2]
              when "φ"
                skip += 2
                a << "ef"
            else
              a << "ef"
              skip += 1
            end
          when "ι"
            a << "i"
            skip += 1
        else
          a << "e"
        end

      when "γ"
        case h[i+1]
          when "γ"
            a << "g"
            skip += 1
        else
          a << "g"
        end

      when "ι"
        case h[i+1]
          when "ι"
            a << "i"
            skip += 1
        else
          a << "i"
        end

      when "σ"
        case h[i+1]
          when "σ"
            a << "s"
            skip += 1
        else
          a << "s"
        end

      when "η"
        case h[i+1]
          when "υ"
            a << "if"
            skip += 1
        else
          a << "i"
        end

      when "μ"
        case h[i+1]
          when "π"
            a << "b"
            skip += 1
          when "μ"
            a << "m"
            skip += 1
        else
          a << "m"
        end

      when "ν"
        case h[i+1]
          when "τ"
            a << "d"
            skip += 1
          when "ν"
            a << "n"
            skip += 1
        else
          a << "n"
        end

      when "τ"
        case h[i+1]
          when "ζ"
            a << "ts"
            skip += 1
          when "σ"
            a << "ts"
            skip += 1
          when "τ"
            a << "t"
            skip += 1
        else
          a << "t"
        end

      when "ο"
        case h[i+1]
          when "ι"
            a << "i"
            skip += 1
          when "υ"
            a << "u"
            skip += 1
        else
          a << "o"
        end

      when "υ"
        case h[i+1]
          when "ι"
            a << "i"
            skip += 1
        else
          a << "i"
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
  data.execute(105)
  rows = data.fetch_many(max_rows)
  file = File.open("../metaforat/greek_transcriptions.txt","w")
  
  loop do
     rows = data.fetch_many(max_rows)
     rows.each do |row|
       row[1].force_encoding("utf-8").encode("utf-8") #ruby is not always able to detect encoding correctly
       #puts "#{row[0]} - #{remove_accent(row[0])}"
       #puts remove_accent(row[0])
       file << "#{Unicode.downcase(row[1])} - [#{transcription(row[1])}]\n"
       #update.execute(transcription(row[1]), row[0])
     end
     break if rows.count < max_rows      
  end

  file.close
rescue DBI::DatabaseError => e
   puts "An error occurred"
   puts "Error code:    #{e.err}"
   puts "Error message: #{e.errstr}"
ensure
   database.disconnect if database
end
