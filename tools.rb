TOOLS = [
  {
    type: "function",
    function: {
      name: "ls",
      description: "Lists files in a directory.",
      parameters: {
        type: "object",
        properties: {
          path: {
            type: "string",
            description: "Directory to list. Defaults to current directory."
          },
          flags: {
            type: "string",
            description: "Optional ls flags, e.g. -l, -a."
          }
        }
      }
    }
  },
  {
    type: "function",
    function: {
      name: "cat",
      description: "Reads the contents of a file.",
      parameters: {
        type: "object",
        properties: {
          path: {
            type: "string",
            description: "Path to the file to read."
          }
        },
        required: ["path"]
      }
    }
  },
  {
    type: "function",
    function: {
      name: "grep",
      description: "Searches for a string or regex pattern in files.",
      parameters: {
        type: "object",
        properties: {
          pattern: {
            type: "string",
            description: "String or regex pattern to search for."
          },
          path: {
            type: "string",
            description: "File or directory to search in."
          },
          flags: {
            type: "string",
            description: "Optional grep flags, e.g. -i, -r."
          }
        },
        required: ["pattern", "path"]
      }
    }
  }
]