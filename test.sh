#!/usr/bin/env bash

if [[ ! -d "tests" ]]; then
  mkdir tests
fi

for day in "$@"
do
  if [[ $day -eq "all" ]]; then
    for i in $(seq 1 25);
    do
      if [[ ! -d "d${i}" ]]; then
        continue
      fi
      printf "Day %d Results:\n" $i
      odin test "d${i}" -out:tests/"d${i}"
      printf "\n"
    done
    exit 0
  fi

  if [[ $day -gt 0 && $day -lt 26 ]]; then
    if [[ ! -d "d${day}" ]]; then
      printf "Day %d not found\n\n" $day
      continue
    fi

    printf "Day %d Results:\n" $day
    odin test "d${day}" -out:tests/"d${i}"
    printf "\n"
  fi
done
