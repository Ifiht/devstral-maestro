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

url = ENV['OLLAMA_URL'] || "http://127.0.0.1:11434/api/chat"
MODEL = ENV['MODEL_NAME'] || "devstral-small-2"
LLMURI = URI(url)

msgs = [
    { role: "system", content: "You are an agentic AI with access to tools." }
]
TOOLS = [
    {
        type: 'function',
        function: {
            name: 'list_files',
            description: 'Lists all files in the current directory.',
            parameters: {
                type: 'object',
                properties: {}
            }
        }
    }
]

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
    args = "" if args.nil? || args == {} || args.empty?
    puts "[System]: executing shell command '#{tool_name} #{args}'"
    result = ""
    case tool_name
    when "list_files"
        result = %x(ls #{args})
    else
        result = "Unknown tool: #{tool_name}"
    end
    return result
end

loop do
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

        puts "[#{MODEL}]: #{final_msg["content"]}"
    else
        puts "[#{MODEL}]: #{msg["content"]}"
    end
end
