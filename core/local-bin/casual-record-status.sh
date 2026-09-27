#!/bin/bash
PID_FILE="$HOME/.cache/casual-record/wf-recorder.pid"
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "REC"
else
    echo "Casual"
fi
