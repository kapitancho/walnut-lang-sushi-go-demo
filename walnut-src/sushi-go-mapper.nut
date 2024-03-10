module sushi-go-mapper %% sushi-go-dto, sushi-go-behavior:

PlayerCardMove ==> PlayerMove @ UnknownCard :: {
    chopsticksExchange = $.chopsticksExchange;
    [
        chosenCard: ?noError($.chosenCard->as(type{SushiGoCard})),
        chopsticksExchange: ?whenTypeOf(chopsticksExchange) is {
            type{NoCard}: NoChopsticksExchange[],
            type{CardName}: ?noError(chopsticksExchange->as(type{SushiGoCard}))
        }
    ]
};

CardName ==> SushiGoCard @ UnknownCard :: ?whenValueOf($) is {
    'tempura': SushiGoCard.Tempura,
    'sashimi': SushiGoCard.Sashimi,
    'dumpling': SushiGoCard.Dumpling,
    'maki-roll-3': SushiGoCard.MakiRoll3,
    'maki-roll-2': SushiGoCard.MakiRoll2,
    'maki-roll-1': SushiGoCard.MakiRoll1,
    'nigiri-squid': SushiGoCard.NigiriSquid,
    'nigiri-salmon': SushiGoCard.NigiriSalmon,
    'nigiri-egg': SushiGoCard.NigiriEgg,
    'pudding': SushiGoCard.Pudding,
    'wasabi': SushiGoCard.Wasabi,
    'chopsticks': SushiGoCard.Chopsticks,
    ~: Error(UnknownCard[cardName: $])
};

SushiGoCard ==> CardName :: ?whenValueOf($) is {
    SushiGoCard.Tempura: 'tempura',
    SushiGoCard.Sashimi: 'sashimi',
    SushiGoCard.Dumpling: 'dumpling',
    SushiGoCard.MakiRoll3: 'maki-roll-3',
    SushiGoCard.MakiRoll2: 'maki-roll-2',
    SushiGoCard.MakiRoll1: 'maki-roll-1',
    SushiGoCard.NigiriSquid: 'nigiri-squid',
    SushiGoCard.NigiriSalmon: 'nigiri-salmon',
    SushiGoCard.NigiriEgg: 'nigiri-egg',
    SushiGoCard.Pudding: 'pudding',
    SushiGoCard.Wasabi: 'wasabi',
    SushiGoCard.Chopsticks: 'chopsticks'
};

PlayroomTable ==> TableData :: {
    activeGame = $.activeGame->value;
    [
        number: $.tableNumber,
        joinedPlayers: $.players->players->length,
        playersCount: $.playersCountRange,
        currentGame: ?whenTypeOf(activeGame) is {
            type{ActiveGame}: {
                /*activeGame->LOGDEBUG;*/
                d = activeGame->as(type{ActiveGameData});
                ?whenTypeOf(d) is {
                    type{ActiveGameData}: d,
                    ~: [
                        id: 'G-xxx',
                        players: ['xxx'],
                        completedRounds: [],
                        activeRound: [openCards: [:]]
                    ]
                }
            },
            type{NoActiveGame}: activeGame
        }
    ]
};

PlayroomGame ==> GameData :: {
    ?whenTypeOf($) is {
        type{ActiveGame}: $->as(type{ActiveGameData}),
        type{CompletedGame}: $->as(type{CompletedGameData})
    }
};

ActiveGame ==> ActiveGameData @ MapItemNotFound|IndexOutOfRange :: {
    playerIds = $.players->playerIds;
    playerNamesByIndex = $.players->playerNames->flip;
    [
        id: $.gameId,
        players: $.players->playerNames,
        completedRounds: ?noError($.state->value.completedRounds->map(
            ^PlayersCards => Result<CompletedGameRoundData, MapItemNotFound|IndexOutOfRange> :: {
                playersCards = #;
                [cards:
                    ?noError(playerNamesByIndex->map(^Integer => Result<Array<CardName, ..10>, MapItemNotFound|IndexOutOfRange> ::
                        ?noError(playersCards->cards->item(?noError(playerIds->item(#))))
                            ->map(^SushiGoCard => CardName :: #->as(type{CardName}))
                    ))
                ]
            }
        )),
        activeRound: [
            openCards: ?noError(
                playerNamesByIndex->map(
                    ^Integer => Result<Array<CardName, ..10>, MapItemNotFound|IndexOutOfRange> ::
                        ?noError(
                            $.state->value.activeRound->openCards->cards->item(
                                ?noError(
                                    playerIds->item(#)
                                )
                            )
                        )->map(
                            ^SushiGoCard => CardName :: #->as(type{CardName})
                        )
                )
            )
        ]
    ]
};

getPlayerGameDataFor = ^[~ActiveGame, ~PlayerId] => Result<PlayerGameData, MapItemNotFound|IndexOutOfRange> :: {
    activeGameData = ?noError(#.activeGame->as(type{ActiveGameData}));
    hiddenCards = ?noError(#.activeGame->activeRound->hiddenCards->cards->item(#.playerId));
    [
        id: activeGameData.id,
        players: activeGameData.players,
        completedRounds: activeGameData.completedRounds,
        playerActiveRound: [
            openCards: activeGameData.activeRound.openCards,
            playerHiddenCards: hiddenCards->map(^SushiGoCard => CardName :: #->as(type{CardName}))
        ]
    ]
};

CompletedGame ==> CompletedGameData @ MapItemNotFound|IndexOutOfRange :: {
    playerIds = $.players->playerIds;
    playerNamesByIndex = $.players->playerNames->flip;
    [
        id: $.gameId,
        players: $.players->playerNames,
        completedRounds: ?noError($.completedGameRounds->cardsByRound->map(
            ^PlayersCards => Result<CompletedGameRoundData, MapItemNotFound|IndexOutOfRange> :: {
                playersCards = #;
                [cards:
                    ?noError(playerNamesByIndex->map(^Integer => Result<Array<CardName, ..10>, MapItemNotFound|IndexOutOfRange> ::
                        ?noError(playersCards->cards->item(?noError(playerIds->item(#))))
                            ->map(^SushiGoCard => CardName :: #->as(type{CardName}))
                    ))
                ]
            }
        ))
    ]
};
