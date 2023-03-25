# Bash script for starting a new screen session

This Bash script starts a new screen session and prompts the user to enter a name for the session. It can be useful when you need to start a new screen session and want to give it a descriptive name for easier identification.

## Usage

To use this script, simply run it in a Bash terminal. It will prompt you to enter a name for the new screen session. Once you enter a name, the script will start a new screen session with the specified name.

## Script

```bash
#!/bin/bash

# Prompt user to enter a name for the new session
read -p "Enter a name for the new session: " session_name

# Start a new screen session with the specified name
screen -S "$session_name"
```

## Explanation

The script consists of two parts:

1. Prompt user to enter a name for the new session:

   ```bash
   read -p "Enter a name for the new session: " session_name
   ```

   This command prompts the user to enter a name for the new screen session. The entered name is stored in the `session_name` variable.

2. Start a new screen session with the specified name:

   ```bash
   screen -S "$session_name"
   ```

   This command starts a new screen session with the name stored in the `session_name` variable. The `-S` option is used to specify the session name, and the name is enclosed in double quotes to ensure that any spaces or special characters in the name are handled correctly.

## Note

The user needs to enter a name for the new screen session in order to use this script. If you want to provide a more user-friendly interface, you could modify the script to suggest a default name or provide a menu of pre-defined session names.
