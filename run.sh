#!/usr/bin/env bash

SPEED_FLAGS="-o:speed -no-bounds-check -disable-assert"

if [[ ! -d "builds" ]]; then
  mkdir builds
fi

for day in "$@"
do
  if [[ "$day" = "all" ]]; then
    for i in $(seq 1 25);
    do
      if [[ ! -d "d${i}" ]]; then
        continue
      fi
      printf "Day %d Results:\n" $i
      odin run "d${i}" $SPEED_FLAGS -out:builds/"d${i}" -- "./input/d${i}.txt"
      printf "\n"
    done
    exit 0
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
    odin run "d${day}" $SPEED_FLAGS -out:builds/"d${day}" -- "./input/d${day}.txt"
    printf "\n"
  fi
done
