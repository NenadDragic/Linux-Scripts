# Bash script for displaying and connecting to screen sessions

This Bash script displays a list of all running screen sessions and prompts the user to select one to connect to. It can be useful when you have multiple screen sessions running and need to switch between them quickly.

## Usage

To use this script, simply run it in a Bash terminal. It will display a list of all running screen sessions with their IDs and names (if any). You can then enter the ID of the session you want to connect to, and the script will connect you to that session.

## Script

```bash
#!/bin/bash

# List all screen sessions
screen -ls

# Prompt user to select a session to connect to
read -p "Enter the session ID to connect to: " session_id

# Connect to the selected session
screen -r $session_id
```

## Explanation

The script consists of three parts:

1. List all screen sessions:

   ```bash
   screen -ls
   ```

   This command lists all currently running screen sessions along with their IDs and names (if any).

2. Prompt user to select a session to connect to:

   ```bash
   read -p "Enter the session ID to connect to: " session_id
   ```

   This command prompts the user to enter the ID of the screen session they want to connect to. The entered ID is stored in the `session_id` variable.

3. Connect to the selected session:

   ```bash
   screen -r $session_id
   ```

   This command connects to the screen session with the ID stored in the `session_id` variable.

## Note

The user needs to know the session ID in order to connect to a screen session using this script. If you want to provide a more user-friendly interface, you could modify the script to display a list of available sessions with a numbered menu, or allow the user to search for sessions by name or other criteria.
