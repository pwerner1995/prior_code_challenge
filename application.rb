require 'socket'
require 'uri'
require 'yaml/store'

server = TCPServer.new(9999)

store = YAML::Store.new("store.yml")


def input_form
    <<~STR
      <form action="/add/data" method="post" enctype="application/x-www-form-urlencoded">
        <p><label>File <input type="file" name="file" accept=".txt"></label></p>
        <p><button>Submit Data</button></p>
      </form>
    STR
end

def decode_data(body)
    
    file_name = URI.decode_www_form(body)[0][1]
    # file = File.open("#{file_name}")
    puts Dir.pwd
    file_data = File.read("#{Dir.pwd}/input_data/#{file_name}")
    # file_data = File.read("#{file_name}")
    if file_data.include? ","
        File.foreach("#{Dir.pwd}/input_data/#{file_name}"){|line| puts line}
        # puts "Comma delimited: #{file_data.foreach{|line| puts line}}" 
    elsif file_data.include? "|"
        puts "Pipe delimited: #{file_data.split("|")}" 
    else
        puts "space delimited: #{file_data.split(" ")}" 
    end

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
            all_data = store[:profile_data]
        end
        if all_data != nil
            all_data.each do |data|
                response_message << "<li> #{data[:first_name]} #{data[:last_name]} #{data[:gender]} #{data[:dob]} #{data[:favorite_color]}</li>"
            end
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
        new_data = decode_data(body)

        # WRITE user input to file
        if new_data != nil
            store.transaction do 
                store[:data] << new_data.transform_keys(&:to_sym)
            end
        end
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
