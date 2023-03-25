#!/bin/bash

# List all screen sessions
screen -ls

# Prompt user to select a session to connect to
read -p "Enter the session ID to connect to: " session_id

# Connect to the selected session
screen -r $session_id
