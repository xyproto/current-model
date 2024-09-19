const std = @import("std");

const CONFIG_FILE = "/etc/current-model.conf";
const VERSION = "1.0.0";

// Function to read the contents of the configuration file
fn readFile() ![]u8 {
    var file = try std.fs.cwd().openFile(CONFIG_FILE, .{ .read = true });
    defer file.close();

    return try file.readToEndAlloc(std.heap.page_allocator);
}

// Function to write the contents to the configuration file
fn writeFile(content: []const u8) !void {
    var file = try std.fs.cwd().openFile(CONFIG_FILE, .{ .write = true });
    defer file.close();

    try file.writeAll(content);
}

// Parse the configuration file and return a list of (task, model) pairs
fn parseConfig(contents: []const u8) []const []const u8 {
    return std.mem.tokenize(contents, "\n");
}

// Get the model for a specific task
fn getModelForTask(task: []const u8) !void {
    var fileContents = try readFile();
    var lines = parseConfig(fileContents);

    for (lines) |line| {
        if (std.mem.startsWith(u8, line, task ++ "=")) {
            var model = line[task.len + 1..]; // Extract the model part
            std.debug.print("{s}\n", .{model});
            return;
        }
    }

    std.debug.print("Error: No model configured for task '{s}'\n", .{task});
    std.os.exit(1);
}

// Set or update a model for a specific task
fn setModelForTask(task: []const u8, model: []const u8) !void {
    var fileContents = try readFile();
    var lines = parseConfig(fileContents);

    var newConfig = std.heap.page_allocator.alloc(u8, fileContents.len + task.len + model.len + 10) catch {
        std.debug.print("Error: Could not allocate memory for new config.\n", .{});
        std.os.exit(1);
    };
    defer std.heap.page_allocator.free(newConfig);

    var found = false;
    var index: usize = 0;

    for (lines) |line| {
        if (std.mem.startsWith(u8, line, task ++ "=")) {
            // Replace the line with the new model
            var newLine = std.fmt.bufPrint(std.heap.page_allocator, "{s}={s}\n", .{task, model}) catch {
                std.debug.print("Error: Could not format new line.\n", .{});
                std.os.exit(1);
            };
            std.mem.copy(u8, newConfig[index..index + newLine.len], newLine);
            index += newLine.len;
            found = true;
        } else {
            std.mem.copy(u8, newConfig[index..index + line.len + 1], line ++ "\n");
            index += line.len + 1;
        }
    }

    if (!found) {
        // If the task was not found, add it to the end of the config
        var newLine = std.fmt.bufPrint(std.heap.page_allocator, "{s}={s}\n", .{task, model}) catch {
            std.debug.print("Error: Could not format new task.\n", .{});
            std.os.exit(1);
        };
        std.mem.copy(u8, newConfig[index..index + newLine.len], newLine);
        index += newLine.len;
    }

    try writeFile(newConfig[0..index]);
    std.debug.print("Successfully set model for task '{s}' to '{s}'.\n", .{task, model});
}

// Print the current configuration
fn showConfig() !void {
    var fileContents = try readFile();
    std.debug.print("{s}", .{fileContents});
}

// Print the usage instructions
fn printHelp() void {
    std.debug.print(
        "Usage: current-model [OPTIONS] COMMAND [ARGS]\n" ++
        "\n" ++
        "Options:\n" ++
        "  --help       Show this message and exit\n" ++
        "  --version    Show the version of this utility and exit\n" ++
        "\n" ++
        "Commands:\n" ++
        "  show                 Show all task-to-model mappings\n" ++
        "  <task>               Get the model for a specific task\n" ++
        "  set <task> <model>   Set or update the model for a specific task\n",
        .{}
    );
}

// Print the version information
fn printVersion() void {
    std.debug.print("current-model version {s}\n", .{VERSION});
}

pub fn main() !void {
    const args = std.process.argsAlloc(std.heap.page_allocator) catch {
        std.debug.print("Error: Failed to allocate args.\n", .{});
        return;
    };
    defer std.heap.page_allocator.free(args);

    if (args.len == 0 or args.len > 4) {
        printHelp();
        return;
    }

    const command = args[1];

    if (std.mem.eql(u8, command, "--help")) {
        printHelp();
        return;
    } else if (std.mem.eql(u8, command, "--version")) {
        printVersion();
        return;
    } else if (std.mem.eql(u8, command, "show")) {
        try showConfig();
        return;
    } else if (std.mem.eql(u8, command, "set")) {
        if (args.len != 4) {
            std.debug.print("Error: Invalid number of arguments for 'set' command.\n", .{});
            printHelp();
            return;
        }
        try setModelForTask(args[2], args[3]);
        return;
    } else {
        // Treat the argument as a task name
        if (args.len != 2) {
            std.debug.print("Error: Invalid number of arguments.\n", .{});
            printHelp();
            return;
        }
        try getModelForTask(command);
    }
}
