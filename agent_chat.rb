require 'net/http'
require 'json'
require 'uri'

if File.exist?('.env')
    File.foreach('.env') do |line|
        next if line.strip.empty?
        key, val = line.strip.split('=', 2)
        ENV[key] = val if key && val
    end
end

url = ENV['OLLAMA_URL'] || "http://127.0.0.1:11434/api/generate"
model = ENV['MODEL_NAME'] || "devstral-small-2"
uri = URI(url)

memory = []

puts "Chatting with #{model} at #{uri}. Type 'exit' to quit."

loop do
    print "\n[User]: "
    input = gets.chomp
    break if input.downcase == "exit"

    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.body = {
        model: model,
        prompt: input,
        context: memory,
        stream: false
    }.to_json

    begin
        print "[#{model}]: "
        res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
        pjson = JSON.parse(res.body)
        puts pjson["response"]
        # Update Memory:
        memory = pjson["context"]
    rescue StandardError => e
        puts "Error: #{e.message}"
    end
end
