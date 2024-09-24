# current-model

# THIS IS A WORK IN PROGRESS!

`current-model` is a lightweight utility to configure and query models for various tasks. It reads from `/etc/current-model.conf`, which stores task-to-model mappings.

## Features

- Retrieve the model for a specific task
- List all task-to-model mappings
- Set or update models for specific tasks

## Installation

To build the `current-model` utility from source, use the provided `Makefile`:

```bash
make
```

On Arch Linux, you will need the zig package installed. On macOS, install zig via Homebrew:

```bash
brew install zig
```

Once built, you can install the utility by copying the binary to /usr/bin:

```bash
sudo install -Dm644 current-model /usr/bin/current-model
```

Or on BSD or macOS (use `doas` or `sudo` if needed):

```bash
install -m644 current-model /usr/local/bin/current-model
```

## Usage

Get the model for a specific task:

```bash
current-model <task>
```

Example:

```bash
current-model codegen
```

Set the model for a task:

```bash
sudo current-model set <task> <model>
```

Example:

```bash
sudo current-model set codegen llama3.1:latest
```

List all task-to-model mappings:

```bash
current-model show
```

## Configuration

The configuration file is located at /etc/current-model.conf. Example:

```ini
chat=gemma2:latest
codegen=qwen2.5:32b
imagedesc=llava:latest
```

## License

* BSD-3
