#!/bin/bash

# Prompt user to enter a name for the new session
read -p "Enter a name for the new session: " session_name

# Start a new screen session with the specified name
screen -S "$session_name"
