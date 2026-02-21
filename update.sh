#!/bin/bash

read -p "Enter commit message: " msg
echo

echo "Adding all files..."
git add .

echo
echo "Committing with message: \"$msg\""
git commit -m "$msg"

echo
echo "Pushing to origin/main..."
git push origin main

echo
echo "Done! :D"
