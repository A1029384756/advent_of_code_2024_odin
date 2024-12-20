#!/usr/bin/env bash

if [[ ! -d "tests" ]]; then
  mkdir tests
fi

exit_code=0

for day in "$@"
do
  if [[ "$day" = "all" ]]; then
    for i in $(seq 1 25);
    do
      if [[ ! -d "d${i}" ]]; then
        continue
      fi
      printf "Day %d Results:\n" $i
      if ! odin test "d${i}" -out:tests/"d${i}"; then
        exit_code=1
      fi
      printf "\n"
    done
    exit $exit_code
  fi

  re='^[0-9]+$'
  if ! [[ $day =~ $re ]] ; then
    echo "error: Day not a number" >&2; exit 1
  fi

  if [[ $day -gt 0 && $day -lt 26 ]]; then
    if [[ ! -d "d${day}" ]]; then
      printf "Day %d not found\n\n" $day
      continue
    fi

    printf "Day %d Results:\n" $day
    if ! odin test "d${day}" -out:tests/"d${day}"; then
      exit_code=1
    fi
    printf "\n"
  fi
done

exit $exit_code
