#!/usr/bin/env bash
# Run before git push — blocks trainer-only paths from reaching the student GitHub repo.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BLOCKED=(
  'Instructor_Materials/'
  '_private_validation/'
  'Module_04_Hybrid_Architecture/'
  'Module_05_Logstash/'
  'Module_06_Filebeat/'
  'Module_07_Metricbeat/'
  'Module_08_AWS_GuardDuty/'
  'assets/module_04/'
  'assets/module_05/'
  'assets/module_06/'
  'assets/module_07/'
  'assets/module_08/'
)

FAIL=0
STAGED=$(git diff --cached --name-only 2>/dev/null || true)

if [ -z "$STAGED" ]; then
  echo "No staged files. Checking tracked tree for blocked paths..."
  STAGED=$(git ls-files)
fi

for path in $STAGED; do
  for b in "${BLOCKED[@]}"; do
    if [[ "$path" == "$b"* ]] || [[ "$path" == *"/${b}"* ]]; then
      echo "BLOCKED: $path (matches $b)"
      FAIL=1
    fi
  done
  case "$path" in
    *_Instructor.md|*_Student.md|*.env|.env|*.pem|credentials.csv|credentials.json)
      echo "BLOCKED: $path (trainer/secret pattern)"
      FAIL=1
      ;;
  esac
done

# Heuristic: long-lived AWS key in diff
if git diff --cached -U0 2>/dev/null | grep -qE 'AKIA[0-9A-Z]{16}'; then
  echo "BLOCKED: staged diff may contain AWS access key IDs — review before push"
  FAIL=1
fi

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "Push aborted. Unstage blocked files or move them under gitignored trainer folders."
  exit 1
fi

echo "OK — staged/tracked files look student-safe."
exit 0
