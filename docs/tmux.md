# Persistent WSL Sessions with tmux in Cursor AI

## Overview

This document explains how to maintain persistent WSL (Windows Subsystem for Linux) sessions when working with Cursor's AI assistant, allowing for continuous state across multiple AI responses without losing terminal context.

## The Problem

By default, when using Cursor's AI terminal commands:
- Each AI response may start a new terminal session
- Working directory, environment variables, and session state are lost
- Interactive sessions like WSL get backgrounded and become inaccessible
- No easy way to maintain continuous development workflow

## The Solution: tmux-based Persistent Sessions

Using `tmux` (terminal multiplexer), we can create a persistent WSL session that:
- ✅ Maintains state across all AI interactions
- ✅ Preserves working directory changes
- ✅ Keeps environment variables
- ✅ Allows complex multi-step workflows
- ✅ Works entirely through PowerShell commands

## How It Works

### 1. Create a Named tmux Session

```powershell
wsl tmux new-session -d -s "cursor-ai-session"
```

This creates a detached tmux session named "cursor-ai-session" that runs in the background.

### 2. Send Commands to the Session

```powershell
wsl tmux send-keys -t cursor-ai-session 'your-command-here' Enter
```

This sends any command to the persistent session as if you typed it directly.

### 3. Capture Session Output

```powershell
wsl tmux capture-pane -t cursor-ai-session -p
```

This retrieves the current output/history from the session.

## Implementation Steps

### Step 1: Initial Setup
```powershell
# Create the persistent session
wsl tmux new-session -d -s "cursor-ai-session"
```

### Step 2: Execute Commands
```powershell
# Send a command to the session
wsl tmux send-keys -t cursor-ai-session 'pwd' Enter

# Check the result
wsl tmux capture-pane -t cursor-ai-session -p
```

### Step 3: Verify Persistence
```powershell
# Set an environment variable
wsl tmux send-keys -t cursor-ai-session 'export TEST_VAR="Session is persistent!"' Enter

# Change directory
wsl tmux send-keys -t cursor-ai-session 'cd /tmp' Enter

# Verify both persist in later commands
wsl tmux send-keys -t cursor-ai-session 'echo $TEST_VAR && pwd' Enter
wsl tmux capture-pane -t cursor-ai-session -p
```

## The Length Issue and Solutions

### Problem Description
PowerShell console has display width limitations (typically 80-120 characters) that can cause issues:

```powershell
# This command gets truncated in display:
wsl tmux send-keys -t cursor-ai-session "echo 'This is a very long command that exceeds the PowerShell console width limit'"
```

Appears as:
```
PS> wsl tmux send-keys -t cursor-ai-session "echo 'This is a very long command that exceeds the PowerS
```

### Solutions

#### 1. Use Shorter Commands
```powershell
# Instead of long compound commands:
wsl tmux send-keys -t cursor-ai-session "echo 'Hello' && pwd && ls -la" Enter

# Break into separate commands:
wsl tmux send-keys -t cursor-ai-session 'echo Hello' Enter
wsl tmux send-keys -t cursor-ai-session 'pwd' Enter
wsl tmux send-keys -t cursor-ai-session 'ls -la' Enter
```

#### 2. Use Single Quotes
```powershell
# Prefer single quotes to avoid escaping issues:
wsl tmux send-keys -t cursor-ai-session 'echo $TEST_VAR' Enter

# Instead of complex double-quote escaping:
wsl tmux send-keys -t cursor-ai-session "echo \$TEST_VAR" Enter
```

#### 3. Break Complex Operations
```powershell
# For multi-step operations, use multiple send-keys calls:
wsl tmux send-keys -t cursor-ai-session 'cd /project' Enter
wsl tmux send-keys -t cursor-ai-session 'npm install' Enter
wsl tmux send-keys -t cursor-ai-session 'npm run dev' Enter
```

## Usage Patterns

### Development Workflow
```powershell
# Navigate to project
wsl tmux send-keys -t cursor-ai-session 'cd /mnt/c/projects/myapp' Enter

# Install dependencies
wsl tmux send-keys -t cursor-ai-session 'npm install' Enter

# Check status
wsl tmux capture-pane -t cursor-ai-session -p

# Start development server
wsl tmux send-keys -t cursor-ai-session 'npm run dev' Enter
```

### Environment Setup
```powershell
# Set multiple environment variables
wsl tmux send-keys -t cursor-ai-session 'export NODE_ENV=development' Enter
wsl tmux send-keys -t cursor-ai-session 'export API_KEY=your-key-here' Enter
wsl tmux send-keys -t cursor-ai-session 'export PORT=3000' Enter

# Verify settings
wsl tmux send-keys -t cursor-ai-session 'env | grep -E "(NODE_ENV|API_KEY|PORT)"' Enter
wsl tmux capture-pane -t cursor-ai-session -p
```

### Git Operations
```powershell
# Git workflow
wsl tmux send-keys -t cursor-ai-session 'git status' Enter
wsl tmux send-keys -t cursor-ai-session 'git add .' Enter
wsl tmux send-keys -t cursor-ai-session 'git commit -m "Update feature"' Enter
wsl tmux send-keys -t cursor-ai-session 'git push origin main' Enter

# Check results
wsl tmux capture-pane -t cursor-ai-session -p
```

## Session Management

### List Active Sessions
```powershell
wsl tmux list-sessions
```

### Attach to Session (from WSL directly)
```bash
tmux attach-session -t cursor-ai-session
```

### Kill Session When Done
```powershell
wsl tmux kill-session -t cursor-ai-session
```

### Create Multiple Named Sessions
```powershell
# Different sessions for different projects
wsl tmux new-session -d -s "project-frontend"
wsl tmux new-session -d -s "project-backend"
wsl tmux new-session -d -s "project-testing"
```

## Advanced Features

### Send Complex Scripts
```powershell
# Create and execute a multi-line script
wsl tmux send-keys -t cursor-ai-session 'cat > setup.sh << EOF' Enter
wsl tmux send-keys -t cursor-ai-session '#!/bin/bash' Enter
wsl tmux send-keys -t cursor-ai-session 'echo "Setting up environment..."' Enter
wsl tmux send-keys -t cursor-ai-session 'npm install' Enter
wsl tmux send-keys -t cursor-ai-session 'npm run build' Enter
wsl tmux send-keys -t cursor-ai-session 'EOF' Enter
wsl tmux send-keys -t cursor-ai-session 'chmod +x setup.sh && ./setup.sh' Enter
```

### Monitor Long-Running Processes
```powershell
# Start a background process
wsl tmux send-keys -t cursor-ai-session 'npm run dev &' Enter

# Check if it's running
wsl tmux send-keys -t cursor-ai-session 'ps aux | grep node' Enter
wsl tmux capture-pane -t cursor-ai-session -p
```

## Benefits

1. **State Persistence**: Environment variables, working directory, and session state persist across AI interactions
2. **Complex Workflows**: Can execute multi-step development processes without interruption
3. **Background Processes**: Can start servers, watchers, or long-running tasks
4. **History Maintenance**: Full command history and output retained
5. **Multiple Projects**: Can maintain separate sessions for different projects
6. **Debugging Friendly**: Can easily inspect session state and output

## Prerequisites

- Windows Subsystem for Linux (WSL) installed
- tmux installed in WSL: `sudo apt install tmux` (Ubuntu/Debian)
- PowerShell access from Cursor

## Troubleshooting

### Session Not Found
```powershell
# Check if session exists
wsl tmux list-sessions

# Create new session if needed
wsl tmux new-session -d -s "cursor-ai-session"
```

### Command Not Executing
```powershell
# Ensure proper syntax with quotes
wsl tmux send-keys -t cursor-ai-session 'command here' Enter

# Check session output for errors
wsl tmux capture-pane -t cursor-ai-session -p
```

### Length Issues
- Break long commands into smaller parts
- Use single quotes when possible
- Avoid complex compound commands

## Conclusion

This tmux-based approach provides a robust solution for maintaining persistent WSL sessions in Cursor AI, enabling complex development workflows while preserving session state across all interactions. The length issue workarounds ensure reliable command execution despite PowerShell console limitations. 


via ssh we can use wsl to connect to cloud instance 20.86.144.152 with ./omarkey.pem , where username is omar.