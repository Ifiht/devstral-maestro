require 'net/http'
require 'shellwords'
require "open3"
require 'json'
require 'uri'

require_relative 'tools'

if File.exist?('.env')
    File.foreach('.env') do |line|
        next if line.strip.empty?
        key, val = line.strip.split('=', 2)
        ENV[key] = val if key && val
    end
end

url = ENV['OLLAMA_URL'] || "http://127.0.0.1:11434/api/chat"
MODEL = ENV['MODEL_NAME'] || "devstral-small-2"
LLMURI = URI(url)

msgs = []

puts "Chatting with #{MODEL} at #{LLMURI}. Type 'exit' to quit."

def send_request(msgs)
    req = Net::HTTP::Post.new(LLMURI, 'Content-Type' => 'application/json')
    req.body = {
        model: MODEL,
        tools: TOOLS,
        messages: msgs,
        stream: false
    }.to_json
    response_body = Net::HTTP.start(LLMURI.hostname, LLMURI.port) do |http|
        http.request(req).body
    end
    return JSON.parse(response_body)
end

def execute_tool(tool_name, args)
    args ||= {}
    puts "[System]: executing shell command '#{tool_name} #{args}'"
    result = ""
    case tool_name
    when "list_files"
        path  = args["path"]  || "."
        flags = args["flags"] || ""
        result = %x(ls #{flags} #{path})
    when "read_file"
        path = args["path"]
        return "Error: path required" unless path
        result = %x(cat #{path})
    when "search"
        pattern = args["pattern"]
        path    = args["path"]
        flags   = args["flags"] || ""
        return "Error: pattern and path required" unless pattern && path
        result = %x(grep #{flags} #{pattern} #{path})
    else
        result = "Unknown tool: #{tool_name}"
    end
    return result
end

def sanitize_for_speech(text)
  text
    .gsub(/[`*_#<>]/, "")
    .gsub(/\s+/, " ")
    .strip
end

loop do
    llmout = ""
    print "\n[User]: "
    input = gets.chomp
    break if input.downcase == "exit"
    if input.downcase == "debug"
        puts JSON.pretty_generate(msgs)
        next
    end

    msgs << { role: "user", content: input }

    res = send_request(msgs)
    msg = res["message"]
    msgs << msg

    if msg["tool_calls"]
        msg["tool_calls"].each do |tool|
            func_name = tool["function"]["name"]
            func_args = tool["function"]["arguments"]
            output = execute_tool(func_name, func_args)
            msgs << { role: "tool", tool_name: func_name, content: output }
        end

        final_res = send_request(msgs)
        final_msg = final_res["message"]
        msgs << final_msg

        llmout = final_msg["content"]
    else
        llmout = msg["content"]
    end
    puts "[#{MODEL}]: #{llmout}"
    speech_txt = sanitize_for_speech(llmout)
    safe_input = Shellwords.escape(speech_txt)
    %x(python -m piper -m en_GB-cori-high --output_raw -- #{safe_input} | ffplay -nodisp -autoexit -f s16le -ar 22050 -ch_layout mono -)
end
