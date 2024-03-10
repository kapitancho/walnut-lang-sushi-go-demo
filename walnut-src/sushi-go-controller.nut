module sushi-go-controller %% sushi-go-mapper:

==> ListPlayroomTables %% [~Playroom] :: {
    tables = %.playroom->tables;
    ^[:] => Array<TableData> :: tables->all->map(^PlayroomTable => TableData :: #->as(type{TableData}))
};

==> PlayroomTableByTableNumber %% [~Playroom] :: {
    tables = %.playroom->tables;
    ^[~TableNumber] => Result<TableData, UnknownTable> :: ?noError(tables->withNumber(#))->as(type{TableData})
};

==> CurrentGameOnTable %% [~Playroom] :: {
    tables = %.playroom->tables;
    ^[~TableNumber] => Result<ActiveGameData, UnknownTable|NoActiveGame> :: {
        table = ?noError(tables->withNumber(#));
        game = table->activeGame;
        ?whenTypeOf(game) is {
            type{ActiveGame}: game->as(type{ActiveGameData}),
            type{NoActiveGame}: Error(game)
        }
    }
};

==> ListPlayroomGames %% [~Playroom] :: {
    games = %.playroom->games;
    ^[:] => Array<ActiveGameData|CompletedGameData> :: games->all->map(^PlayroomGame => GameData :: #->as(type{GameData}))
};

==> PlayroomGameById %% [~Playroom] :: {
    games = %.playroom->games;
    ^[~GameId] => Result<ActiveGameData|CompletedGameData, UnknownGame> :: {
        game = ?noError(games->withId(#))->as(type{GameData})
    }
};

==> PlayerGame %% [~Playroom] :: {
    games = %.playroom->games;
    ^[~GameId, ~PlayerId] => Result<PlayerGameData|CompletedGameData, UnknownGame|UnknownPlayer> :: {
        game = ?noError(games->withId[gameId: #.gameId]);
        ?whenTypeOf(game) is {
            type{ActiveGame}: {
                playerGameData = getPlayerGameDataFor[game, #.playerId];
                v = ?whenTypeOf(playerGameData) is {
                    type{PlayerGameData}: playerGameData,
                    type{Result<Nothing, MapItemNotFound|IndexOutOfRange>}: Error(UnknownPlayer[#.playerId])
                }
            },
            type{CompletedGame}: game->as(type{CompletedGameData})
        }
    }
};

==> PlayMove %% [~Playroom] :: {
    playroom = %.playroom;
    games = %.playroom->games;
    ^[~GameId, ~PlayerId, ~PlayerCardMove] => Result<PlayerMoveAccepted, UnknownGame|UnknownPlayer|UnknownCard|CardNotInHand|PlayerAlreadyMoved|GameAlreadyCompleted> :: {
        game = ?noError(games->withId[gameId: #.gameId]);
        ?whenTypeOf(game) is {
            type{ActiveGame}: {
                moveResult = game->playMove[
                    playerId: #.playerId,
                    playerMove: ?noError(#.playerCardMove->as(type{PlayerMove}))
                ];
                ?whenTypeOf(moveResult) is {
                    type{Result<Nothing, SushiGoCardNotInHand>}: Error(CardNotInHand[moveResult->error->card->as(type{CardName})]),
                    type{ActiveGame}: PlayerMoveAccepted[],
                    type{CompletedGame}: {
                        playroom->markGameAsCompleted[completedGame: moveResult];
                        PlayerMoveAccepted[]
                    },
                    type{Result<Nothing, UnknownPlayer|PlayerAlreadyMoved>}: moveResult
                }
            },
            type{CompletedGame}: Error(GameAlreadyCompleted[])
        }
    }
};

==> StartGame %% [~Playroom] :: {
    playroom = %.playroom;
    ^[~TableNumber] => Result<GameStarted, UnknownTable|NotEnoughPlayers|GameAlreadyInProgress> :: {
        game = ?noError(playroom->startGame(#));
        GameStarted[#.tableNumber, game->gameId]
    }
};

==> PlayerJoinTable %% [~Playroom] :: {
    tables = %.playroom->tables;
    ^[~TableNumber, ~PlayerData] => Result<PlayerJoined, UnknownTable|TooManyPlayers|PlayerAlreadyOnTable|GameAlreadyInProgress> :: {
        playerId = ?noError(?noError(tables->withNumber[tableNumber: #.tableNumber])->playerJoin(#.playerData));
        PlayerJoined[#.tableNumber, playerId]
    }
};

==> PlayerLeaveTable %% [~Playroom] :: {
    tables = %.playroom->tables;
    ^[~TableNumber, ~PlayerId] => Result<PlayerLeft, UnknownTable|UnknownPlayer|GameAlreadyInProgress> :: {
        ?noError(?noError(tables->withNumber[tableNumber: #.tableNumber])->playerLeave[playerId: #.playerId]);
        PlayerLeft(#)
    }
};

==> NewTable %% [~Playroom] :: {
    tables = %.playroom->tables;
    ^[~NewTableData] => TableAdded :: {
        newTable = tables->new[playersCount: #.newTableData.playersCountRange];
        TableAdded[newTable->number]
    }
};
