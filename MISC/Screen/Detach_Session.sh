#!/bin/bash

# List all screen sessions
screen -ls

# Prompt user to select a session to detach from
read -p "Enter the session ID to detach from: " session_id

# Send CTRL+A and d to detach from the selected session
screen -S $session_id -X detach
