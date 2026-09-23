#!/bin/bash
OUTPUTS=$(mpc outputs)
DAC_ENABLED=$(echo "$OUTPUTS" | grep -i "DAC" | grep -c "is enabled")

if [ "$DAC_ENABLED" -eq 1 ]; then
    echo "DAC"
else
    echo "SYSTEM"
fi
