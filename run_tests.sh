#!/bin/bash

NUM_BOARDS=10  # 🟢 MODIFIED: Make number of boards per size parametric

echo "Cleaning old results..."
rm -rf results/* snapshots/* boards/*  # ✅ Remove all old files

echo "Compiling Java..."
javac -d bin src/game/*.java src/players/*.java
if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi

echo "Generating boards..."
mkdir -p boards snapshots results  # ✅ Ensure directories exist

# ✅ Define board sizes to test (adjust as needed)
BOARD_SIZES=(10 25 50)

# ✅ Generate multiple sets of boards
for size in "${BOARD_SIZES[@]}"; do
    for ((i = 1; i <= NUM_BOARDS; i++)); do  # 🟢 MODIFIED
        java -cp bin game.InstanceGenerator "boards/board_${size}x${size}_$i.dat" $size
    done
done

echo "Running tests..."
> results/TotalScores.txt  # ✅ Ensure fresh scores

while IFS= read -r studentID; do
    totalPercentage=0
    playerLogFile="results/Player${studentID}.log"

    # ✅ Ensure player's log starts fresh
    > "$playerLogFile"

    for size in "${BOARD_SIZES[@]}"; do
        for ((i = 1; i <= NUM_BOARDS; i++)); do  # 🟢 MODIFIED
            boardFile="boards/board_${size}x${size}_$i.dat"
            echo "Testing $studentID on $boardFile..."

            # Use timeout to ensure no infinite loops hang the test
            output=$(timeout 3s java -cp bin game.Tester "$boardFile" "$studentID")
            exit_code=$?

            # Default to minimal score
            score=1
            percentage=0.00

            if [ $exit_code -eq 0 ]; then
                # Try to extract score normally
                score_line=$(echo "$output" | tail -n 1)
                score=$(echo "$score_line" | awk '{print $2}')
                if [[ "$score" =~ ^[0-9]+$ ]]; then
                    maxScore=$((size * size))
                    percentage=$(awk "BEGIN {printf \"%.2f\", 100 * $score / $maxScore}")
                    echo "$size x $size - Game $i: $score ($percentage%)" >> "$playerLogFile"
                else
                    echo "$size x $size - Game $i: invalid score ($score_line)" >> "$playerLogFile"
                fi
            else
                # Timed out or crashed
                echo "$size x $size - Game $i: 1 (timeout/crash) ($score%)" >> "$playerLogFile"
            fi

            totalPercentage=$(awk "BEGIN {print $totalPercentage + $percentage}")
        done
    done

    # ✅ Compute and log final **average percentage score** per student
    totalGames=$(( ${#BOARD_SIZES[@]} * NUM_BOARDS ))  # 🟢 MODIFIED
    avgPercentage=$(awk "BEGIN {printf \"%.2f\", $totalPercentage / $totalGames}")
    echo "$studentID $avgPercentage%" >> results/TotalScores.txt
done < students.txt

echo "Done! Check 'results/TotalScores.txt' and 'snapshots/' for full gameplay."
