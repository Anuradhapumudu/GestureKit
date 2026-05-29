#!/bin/bash
.build/debug/GestureKit > gesturekit.log 2>&1 &
APP_PID=$!
echo "App launched with PID $APP_PID"
sleep 15
kill -9 $APP_PID
