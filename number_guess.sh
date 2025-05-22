#!/bin/bash

# variable for querying db
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# use bash RANDOM to generate a number between 1 - 1000
NUMBER=$(( 1 + $RANDOM % 1000 ))

# prompt for username
echo "Enter your username: "
read USERNAME

# fetch player data
PLAYER_DATA=$($PSQL "
  SELECT username, games_played, best_game
  FROM players
  WHERE username = '$USERNAME'
")

# if player data available
if [[ -n $PLAYER_DATA ]]
then  # save fetched player data in respective variables
  IFS="|" read USERNAME GAMES_PLAYED BEST_GAME <<< "$PLAYER_DATA"
  # print welcome back message with fetched player data
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
else  # print welcome message
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  insert_username=$($PSQL "INSERT INTO players(username, games_played, best_game) VALUES('$USERNAME', 0, 0)")
fi

# prompt for number guess
echo -e "\nGuess the secret number between 1 and 1000: "
# count game
((GAMES_PLAYED++))
while true
do
  read GUESS

  # if input is not an integer prompt again
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then  
    echo "That is not an integer, guess again: "
    continue  # restart loop 
  fi

  # count guess
  ((GUESS_COUNT++))

  # check if guess is higher than secret no.
  if (( GUESS > NUMBER ))
  then  # print feedback for high guess
    echo "It's lower than that, guess again: "
  elif (( GUESS < NUMBER )) 
  then
    # print feedback for low guess
    echo "It's higher than that, guess again: "
  else
    break  # correct guess, exit loop
  fi

done

# print feedback for correct guess
echo -e "\nYou guessed it in $GUESS_COUNT tries. The secret number was $NUMBER. Nice job!"

# check if guess_count is less than player's best_game
if [[ $BEST_GAME -eq 0 || $GUESS_COUNT -lt $BEST_GAME ]]
then  # update best_game
  BEST_GAME=$GUESS_COUNT
fi

# update db with player stats
update_player_stats=$($PSQL "UPDATE players
  SET games_played=$GAMES_PLAYED, best_game=$BEST_GAME
  WHERE username='$USERNAME'
")
