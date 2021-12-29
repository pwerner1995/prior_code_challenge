require 'socket'
require 'uri'
# require 'yaml/store'
require 'pstore'

server = TCPServer.new(9999)

store = PStore.new("store.pstore")

class Profile
    attr_reader :first_name, :last_name, :gender, :favorite_color, :dob
    def initialize(first_name, last_name, gender, favorite_color, dob)
      @first_name = first_name
      @last_name = last_name
      @gender = gender
      @favorite_color = favorite_color
      @dob = dob

    end
end


def input_form
    <<~STR
      <form action="/add/data" method="post" enctype="application/x-www-form-urlencoded">
        <p><label>File <input type="file" name="file" accept=".txt"></label></p>
        <p><button>Submit Data</button></p>
      </form>
    STR
end

def handle_comma_deltimited_data(file_name, store)
    File.foreach("#{Dir.pwd}/input_data/#{file_name}"){|line| 
        new_data = {}
        line = line.split(",")
        # puts "MAP: #{line.split(",").map(&:strip)}"
        new_data[:last_name] = line[0]
        new_data[:first_name] = line[1]
        new_data[:gender] = line[2]
        new_data[:favorite_color] = line[3]
        new_data[:dob] = line[4]
        
        profile = Profile.new(new_data[:first_name], new_data[:last_name], new_data[:gender], new_data[:favorite_color], new_data[:dob])
        puts "Profile: #{profile.first_name}"
        store.transaction do 
            puts "ROOTS: #{store.roots()}"
            if store[:profile_data] == nil || !(store[:profile_data].any?{|p| p.first_name == profile.first_name})
                store[:profile_data] ||= Array.new
                store[:profile_data].push(profile)
            end
                puts "WRITE DATA: #{store[:profile_data]}"
            
        end
        }
end

def handle_pipe_deltimited_data(file_name, store)
    File.foreach("#{Dir.pwd}/input_data/#{file_name}"){|line| 
        new_data = {}
        line = line.split("|")
        # puts "MAP: #{line.split(",").map(&:strip)}"
        new_data[:first_name] = line[0]
        new_data[:last_name] = line[1]
        new_data[:gender] = line[2]
        new_data[:favorite_color] = line[3]
        new_data[:dob] = line[4]
        
        profile = Profile.new(new_data[:first_name], new_data[:last_name], new_data[:gender], new_data[:favorite_color], new_data[:dob])
        puts "Profile: #{profile.first_name}"
        store.transaction do 
            puts "ROOTS: #{store.roots()}"
            if store[:profile_data] == nil || !(store[:profile_data].any?{|p| p.first_name == profile.first_name})
                store[:profile_data] ||= Array.new
                store[:profile_data].push(profile)
            end
                puts "WRITE DATA: #{store[:profile_data]}"
            
        end
        }
end

def handle_space_deltimited_data(file_name, store)
    File.foreach("#{Dir.pwd}/input_data/#{file_name}"){|line| 
        new_data = {}
        line = line.split(" ")
        # puts "MAP: #{line.split(",").map(&:strip)}"
        new_data[:last_name] = line[0]
        new_data[:first_name] = line[1]
        new_data[:gender] = line[2]
        new_data[:favorite_color] = line[3]
        new_data[:dob] = line[4]
        
        profile = Profile.new(new_data[:first_name], new_data[:last_name], new_data[:gender], new_data[:favorite_color], new_data[:dob])
        puts "Profile: #{profile.first_name}"
        store.transaction do 
            puts "ROOTS: #{store.roots()}"
            if store[:profile_data] == nil || !(store[:profile_data].any?{|p| p.first_name == profile.first_name})
                store[:profile_data] ||= Array.new
                store[:profile_data].push(profile)
            end
                puts "WRITE DATA: #{store[:profile_data]}"
            
        end
        }
end


def decode_data(body, store)
    
    file_name = URI.decode_www_form(body)[0][1]
    # file = File.open("#{file_name}")
    puts Dir.pwd
    file_data = File.read("#{Dir.pwd}/input_data/#{file_name}")
    profile_data = []
    # file_data = File.read("#{file_name}")
    if file_data.include? ","
        handle_comma_deltimited_data(file_name, store)    
    elsif file_data.include? "|"
        puts "Pipe delimited: #{file_data.split("|")}" 
    else
        puts "space delimited: #{file_data.split(" ")}" 
    end
    return profile_data
    # puts "NEW DATA: #{file_data}"
end



loop do 
    client = server.accept

    # Accept HTTP request and parse it
    request_line = client.readline
    method_token, target, version_number = request_line.split
    puts "Received a #{method_token} request to #{target} with #{version_number}"

    # Describe what to respond
    case [method_token, target]
    when ["GET", "/show/data"]
        status_code = "200 OK"

        # Display form & data hash
        response_message = "<h1> Profile Data </h1>" << input_form
        response_message << "<ul>"
        # Read Data from file
        all_data = {}
        store.transaction do 
            all_data[:profile_data] = store[:profile_data]
        end
        if all_data[:profile_data] != nil
            puts "STORE DATA: #{all_data[:profile_data].length}"
            puts "STORE DATA: #{all_data[:profile_data].class}"
            puts "STORE DATA: #{all_data[:profile_data][0]}"
            puts "SORTED BY NAME DESC: #{all_data[:profile_data].sort{|a,b| b.first_name <=> a.first_name}}"
            puts "SORTED BY GENDER THEN NAME: #{all_data[:profile_data].sort_by{|a| [a.gender, a.first_name] }}"
            puts "SORTED BY DATE: #{all_data[:profile_data].sort_by{|a| a.dob.split("/").reverse }}"
            
            response_message << "<h3> Sorted by Gender: </h3>"
            for profile in all_data[:profile_data].sort_by{|a| [a.gender, a.last_name] }
                response_message << "<li> #{profile.last_name} #{profile.first_name} #{profile.gender} #{profile.dob} #{profile.favorite_color} </li>"
            end
            
            response_message << "<h3> Sorted by DOB Ascending: </h3>"
            for profile in all_data[:profile_data].sort_by{|a| a.dob.split("/").reverse }
                response_message << "<li> #{profile.last_name} #{profile.first_name} #{profile.gender} #{profile.dob} #{profile.favorite_color} </li>"
            end

            response_message << "<h3> Sorted by Last Name Descending: </h3>"
            for profile in all_data[:profile_data].sort{|a,b| a.last_name <=> b.last_name}.reverse
                response_message << "<li> #{profile.last_name} #{profile.first_name} #{profile.gender} #{profile.dob} #{profile.favorite_color} </li>"
            end
            # all_data[:profile_data].each do |profile_data|
            #     response_message << "<li> #{profile_data[:first_name]} #{profile_data[:last_name]} #{profile_data[:gender]} #{profile_data[:dob]} #{profile_data[:favorite_color]}</li>"
            # end
        end
        response_message << "</ul>"

    when ["POST", "/add/data"]
        status_code = "303 see other"
        response_message = ""

        # Extract the headers from the request 
        headers = {}
        while true
            line = client.readline
            break if line == "\r\n"
            header_name, value = line.split(": ")
            headers[header_name] = value
        end

        # Attain the Content-Length header
        body = client.read(headers['Content-Length'].to_i)

        # Decode it
        new_data = decode_data(body, store)

        

        # WRITE user input to file
        # if new_data != nil
        #     store.transaction do 
        #         store[:profile_data] ||= Array.new
        #         store[:profile_data].push(new_data[0])
        #             # puts "WRITE DATA: #{store[:profile_data]}"ß
                
        #     end
        # end
        # all_data << new_daily_data.transform_keys(&:to_sym)


    else
        response_status_code="200 OK"
        response_message= "✅Received a #{method_token} request to #{target} with #{version_number}"
        content_type ="text/plain"
    end

    # Construct the HTTP response
    http_response = <<~MSG
        HTTP/1.1 #{status_code}
        Content-Type: text/html
        Location: /show/data

        #{response_message}
    MSG

    # Return the HTTP response to client
    client.puts(http_response)
    client.close
end
