# Bash script for detaching from a screen session

This Bash script sends the `CTRL+A` and `d` keys to detach from a running screen session. It can be useful when you need to detach from a screen session and return control to the terminal without closing the session.

## Usage

To use this script, simply run it in a Bash terminal. It will display a list of all running screen sessions with their IDs and names (if any). You can then enter the ID of the session you want to detach from, and the script will send the `CTRL+A` and `d` keys to detach from the session.

## Script

```bash
#!/bin/bash

# List all screen sessions
screen -ls

# Prompt user to select a session to detach from
read -p "Enter the session ID to detach from: " session_id

# Send CTRL+A and d to detach from the selected session
screen -S $session_id -X detach
```

## Explanation

The script consists of three parts:

1. List all screen sessions:

   ```bash
   screen -ls
   ```

   This command lists all currently running screen sessions along with their IDs and names (if any).

2. Prompt user to select a session to detach from:

   ```bash
   read -p "Enter the session ID to detach from: " session_id
   ```

   This command prompts the user to enter the ID of the screen session they want to detach from. The entered ID is stored in the `session_id` variable.

3. Send CTRL+A and d to detach from the selected session:

   ```bash
   screen -S $session_id -X detach
   ```

   This command sends the `CTRL+A` and `d` keys to the screen session with the ID stored in the `session_id` variable. This causes the session to detach and return control to the terminal.

## Note

The user needs to know the session ID in order to detach from a screen session using this script. If you want to provide a more user-friendly interface, you could modify the script to display a list of available sessions with a numbered menu, or allow the user to search for sessions by name or other criteria.
