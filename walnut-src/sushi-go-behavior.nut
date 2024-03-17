module sushi-go-behavior %% sushi-go-model:

==> SushiGoFullDeck :: SushiGoFullDeck(null);

SushiGoCard->cardName(^Null => String) :: {
    ?whenValueOf($) is {
        SushiGoCard.Tempura: 'Tempura',
        SushiGoCard.Sashimi: 'Sashimi',
        SushiGoCard.Dumpling: 'Dumpling',
        SushiGoCard.MakiRoll3: 'Maki Roll (3)',
        SushiGoCard.MakiRoll2: 'Maki Roll (2)',
        SushiGoCard.MakiRoll1: 'Maki Roll (1)',
        SushiGoCard.NigiriSquid: 'Nigiri (Squid)',
        SushiGoCard.NigiriSalmon: 'Nigiri (Salmon)',
        SushiGoCard.NigiriEgg: 'Nigiri (Egg)',
        SushiGoCard.Pudding: 'Pudding',
        SushiGoCard.Wasabi: 'Wasabi',
        SushiGoCard.Chopsticks: 'Chopsticks'
    }
};

SushiGoCard->numberOfCards(^Null => Integer<1..14>) :: {
    ?whenValueOf($) is {
        SushiGoCard.Tempura: 14,
        SushiGoCard.Sashimi: 14,
        SushiGoCard.Dumpling: 14,
        SushiGoCard.MakiRoll3: 8,
        SushiGoCard.MakiRoll2: 12,
        SushiGoCard.MakiRoll1: 6,
        SushiGoCard.NigiriSquid: 5,
        SushiGoCard.NigiriSalmon: 10,
        SushiGoCard.NigiriEgg: 5,
        SushiGoCard.Pudding: 10,
        SushiGoCard.Wasabi: 6,
        SushiGoCard.Chopsticks: 4
    }
};

SushiGoCardNotInHand->card(^Null => SushiGoCard) :: $.sushiGoCard;

SushiGoCard->takeAllCards(^Null => Array<SushiGoCard, 1..14>) :: []->padLeft[length: $->numberOfCards, value: $];

SushiGoFullDeck(Null) :: {
    result = type{SushiGoCard}->values->map(
        ^SushiGoCard => Array<SushiGoCard, 1..14> :: #->takeAllCards
    )->flatten;
    [cards: result]
};
SushiGoFullDeck->shuffle(^Null => SushiGoShuffledDeck) :: {
    SushiGoShuffledDeck($.cards->shuffle)
};

SushiGoShuffledDeck(SushiGoCardArray) :: [cards: Mutable[type{SushiGoCardArray}, #]];

GamePlayerList(Array<Player, 2..5>) :: [players: #];
GamePlayerList->cardsPerPlayer(^Null => Integer<7..10>) :: 12 - $.players->length;
GamePlayerList->playerWithId(^[~PlayerId] => Result<Player, UnknownPlayer>) :: {
    playerId = #.playerId;
    player = $.players->findFirst(^Player => Boolean :: #.playerId == playerId);
    ?whenTypeOf(player) is {
        type{Player}: player,
        type{Result<Nothing, ItemNotFound>}: Error(UnknownPlayer(#))
    }
};
GamePlayerList->players(^Null => Array<Player, 2..5>) :: $.players;
GamePlayerList->playerIds(^Null => Array<PlayerId, 2..5>) :: $.players->map(^Player => PlayerId :: #.playerId);
GamePlayerList->playerNames(^Null => Array<PlayerName, 2..5>) :: $.players->map(^Player => PlayerName :: #.name);

PlayerCards->countCards(^SushiGoCard => Integer<0..>) :: {
    card = #;
    $->filter(^SushiGoCard => Boolean :: # == card)->length
};
PlayerCards->tempuraScore(^Null => Integer<0..>) :: {
    cards = $->countCards(SushiGoCard.Tempura);
    5 * {cards / 2}->asInteger
};
PlayerCards->sashimiScore(^Null => Integer<0..>) :: {
    cards = $->countCards(SushiGoCard.Sashimi);
    10 * {cards / 3}->asInteger
};
PlayerCards->dumplingScore(^Null => Integer<0..>) :: {
    cards = [$->countCards(SushiGoCard.Dumpling), 5]->min;
    {cards * {cards + 1} / 2}->asInteger
};
PlayerCards->makiScore(^Null => Integer<0..>) ::
    {
        {$->countCards(SushiGoCard.MakiRoll1)} +
        {2 * $->countCards(SushiGoCard.MakiRoll2)}
    } + {3 * $->countCards(SushiGoCard.MakiRoll3)};
PlayerCards->nigiriScore(^Null => Integer<0..>) ::
    {
        {3 * $->countCards(SushiGoCard.NigiriSquid)} +
        {2 * $->countCards(SushiGoCard.NigiriSalmon)}
    } + $->countCards(SushiGoCard.NigiriEgg);
PlayerCards->wasabiScore(^Null => Integer<0..>) :: 0;
    /*TODO*/
PlayerCards->puddingsCount(^Null => Integer<0..>) :: $->countCards(SushiGoCard.Pudding);

PlayersCards(Map<PlayerCards>) :: [cards: #];
PlayersCards->cards(^Null => Map<PlayerCards>) :: $.cards;
PlayersCards->scoreByPlayer(^Null => Map<Integer<0..>>) :: {
    cards = $.cards;
    cards->map(^PlayerCards => Integer<0..> ::
        [#->tempuraScore, #->sashimiScore, #->dumplingScore, #->makiScore, #->nigiriScore, #->wasabiScore]->sum
    )
};
PlayersCards->withRemovedByPlayerMoves(^Map<PlayerMove> => Result<PlayersCards, MapItemNotFound|ItemNotFound>) :: {
    cards = $.cards;
    playerMoves = #;
    cards = ?noError(cards->mapKeyValue(^[key: String, value: PlayerCards] => Result<PlayerCards, MapItemNotFound|ItemNotFound> :: {
        playerCards = #.value;
        playerMove = ?noError(playerMoves->item(#.key));
        chosenCard = playerMove.chosenCard;
        chopsticksExchange = playerMove.chopsticksExchange;
        cards = ?noError(playerCards->without(chosenCard));
        cards = ?whenTypeOf(chopsticksExchange) is {
            type{SushiGoCard}: ?noError(cards->without(chopsticksExchange))->insertLast(SushiGoCard.Chopsticks),
            ~: cards
        }
    }));
    PlayersCards(cards)
};
PlayersCards->withAddedByPlayerMoves(^Map<PlayerMove> => Result<PlayersCards, MapItemNotFound|ItemNotFound>) :: {
    cards = $.cards;
    playerMoves = #;
    cards = ?noError(cards->mapKeyValue(^[key: String, value: PlayerCards] => Result<PlayerCards, MapItemNotFound|ItemNotFound> :: {
        playerCards = #.value;
        playerMove = ?noError(playerMoves->item(#.key));
        chosenCard = playerMove.chosenCard;
        chopsticksExchange = playerMove.chopsticksExchange;
        cards = playerCards->insertLast(chosenCard);
        cards = ?whenTypeOf(chopsticksExchange) is {
            /*type{SushiGoCard}: ?noError(cards->without(SushiGoCard.Chopsticks))->insertLast(chopsticksExchange),*/
            type{SushiGoCard}: ?noError(cards->insertLast(chopsticksExchange)->without(SushiGoCard.Chopsticks)),
            ~: cards
        };
        /* temp */
        ?whenTypeOf(cards) is {
            type{PlayerCards}: cards,
            ~: cards->slice[start: 0, length: 10]
        }
    }));
    PlayersCards(cards)
};
PlayersCards->passedToTheNextPlayer(^GamePlayerList => Result<PlayersCards, IndexOutOfRange|MapItemNotFound>) :: {
    playerList = #->playerIds;
    cards = $.cards;
    cards = ?noError(playerList->mapIndexValue(^[index: Integer<0..>, value: PlayerId] => Result<PlayerCards, IndexOutOfRange|MapItemNotFound> :: {
        nextIndex = {#.index + 1} % playerList->length;
        cards->item(?noError(playerList->item(nextIndex)))
    }));
    cards = ?noError(playerList->flip->map(^Integer => Result<Array<SushiGoCard, ..10>, IndexOutOfRange> :: ?noError(cards->item(#))));
    PlayersCards(cards)
};
PlayersCards->puddingsCountByPlayer(^Null => Map<Integer<0..>>) :: $.cards->map(^PlayerCards => Integer<0..> :: #->puddingsCount);

ActiveRound->hiddenCards(^Null => PlayersCards) :: $.hiddenCards;
ActiveRound->openCards(^Null => PlayersCards) :: $.openCards;
ActiveRound->applyPlayerMoves(^Map<PlayerMove> => Result<ActiveRound, MapItemNotFound|ItemNotFound|IndexOutOfRange>) :: {
    playerList = $.playerList;
    openCards = $.openCards;
    hiddenCards = $.hiddenCards;
    playerMoves = #;
    ActiveRound[playerList,
        ?noError(openCards->withAddedByPlayerMoves(playerMoves)),
        ?noError(
            ?noError(hiddenCards->withRemovedByPlayerMoves(playerMoves))
            ->passedToTheNextPlayer(playerList)
        )
    ]
};

CompletedGameRounds->cardsByRound(^Null => Array<PlayersCards, 3..3>) :: $.cardsByRound;
CompletedGameRounds->totalScoreByPlayer(^Null => Result<Map<Integer>, MapItemNotFound>) :: {
    cardsByRound = $.cardsByRound;
    playerList = $.playerList;
    scoresByRound = cardsByRound->map(^PlayersCards => Map<Integer<0..>> :: #->scoreByPlayer);
    puddingCountsByRound = cardsByRound->map(^PlayersCards => Map<Integer<0..>> :: #->puddingsCountByPlayer);
    puddingCountsByPlayer = ?noError(playerList->playerIds->flipMap(^PlayerId => Result<Integer<0..>, MapItemNotFound> ::
        {?noError(puddingCountsByRound->item(0)->item(#)) +
        ?noError(puddingCountsByRound->item(1)->item(#))} +
        ?noError(puddingCountsByRound->item(2)->item(#))
    ));
    minPuddings = puddingCountsByPlayer->values->min;
    maxPuddings = puddingCountsByPlayer->values->max;
    playersWithMinPuddings = puddingCountsByPlayer->filter(^Integer => Boolean :: # == minPuddings)->keys;
    playersWithMaxPuddings = puddingCountsByPlayer->filter(^Integer => Boolean :: # == maxPuddings)->keys;
    pointsForMinPuddings = {6 / playersWithMinPuddings->length}->asInteger;
    pointsForMaxPuddings = {-6 / playersWithMaxPuddings->length}->asInteger;

    playerList->playerIds->flipMap(^PlayerId => Result<Integer, MapItemNotFound> ::
        {{?noError(scoresByRound->item(0)->item(#)) +
        ?noError(scoresByRound->item(1)->item(#))} +
        ?noError(scoresByRound->item(2)->item(#))} +
        {?whenIsTrue { playersWithMinPuddings->contains(#) : pointsForMinPuddings, ~: 0 } +
        ?whenIsTrue { playersWithMaxPuddings->contains(#) : pointsForMaxPuddings, ~: 0 }}
    )
};

SushiGoShuffledDeck->dealCards(^GamePlayerList => Result<PlayersCards, ItemNotFound>) :: {
    players = #->playerIds;
    deck = $.cards;
    cardsPerPlayer = #->cardsPerPlayer;
    cardsToDeal = cardsPerPlayer * players->length;

    cards = ?noError(players->flipMap(^PlayerId => Result<Array<SushiGoCard, 4..10>, ItemNotFound> ::
        1->upTo(cardsPerPlayer)->map(
            ^Integer => Result<SushiGoCard, ItemNotFound> :: ?noError(deck->POP))
    ));
    PlayersCards(cards)
};

ActiveGame[~GameId, ~TableNumber, players: GamePlayerList] %% [~SushiGoFullDeck] :: {
    deck = %.sushiGoFullDeck->shuffle;
    cards = deck->dealCards(#.players);
    /* TEMP */
    cards = ?whenTypeOf(cards) is {
        type{PlayersCards}: cards,
        ~: PlayersCards([:])
    };
    completedRounds = ?whenValueOf(#.gameId) is {
        'G-20': [
            PlayersCards[
                A: [SushiGoCard.Tempura, SushiGoCard.Sashimi, SushiGoCard.Dumpling],
                B: [SushiGoCard.NigiriSquid, SushiGoCard.NigiriSquid, SushiGoCard.Wasabi],
                C: [SushiGoCard.NigiriSalmon, SushiGoCard.Sashimi, SushiGoCard.MakiRoll3]
            ]
        ],
        'G-21': [
            PlayersCards[
                A: [SushiGoCard.Tempura, SushiGoCard.Sashimi, SushiGoCard.Dumpling],
                B: [SushiGoCard.NigiriSquid, SushiGoCard.NigiriSquid, SushiGoCard.Wasabi],
                C: [SushiGoCard.NigiriSalmon, SushiGoCard.Sashimi, SushiGoCard.MakiRoll3]
            ]
        ],
        'G-22': [
            PlayersCards[
                A: [SushiGoCard.Tempura, SushiGoCard.Sashimi, SushiGoCard.Dumpling],
                B: [SushiGoCard.NigiriSquid, SushiGoCard.NigiriSquid, SushiGoCard.Wasabi],
                C: [SushiGoCard.NigiriSalmon, SushiGoCard.Sashimi, SushiGoCard.MakiRoll3]
            ]
        ],
        'G-23': [
            PlayersCards[
                A: [SushiGoCard.Tempura, SushiGoCard.Sashimi, SushiGoCard.Dumpling],
                B: [SushiGoCard.NigiriSquid, SushiGoCard.NigiriSquid, SushiGoCard.Wasabi],
                C: [SushiGoCard.NigiriSalmon, SushiGoCard.Sashimi, SushiGoCard.MakiRoll3]
            ],
            PlayersCards[
                A: [SushiGoCard.Tempura, SushiGoCard.Sashimi, SushiGoCard.Dumpling],
                B: [SushiGoCard.NigiriSquid, SushiGoCard.NigiriSquid, SushiGoCard.Wasabi],
                C: [SushiGoCard.NigiriSalmon, SushiGoCard.Sashimi, SushiGoCard.MakiRoll3]
            ]
        ],
        ~: []
    };
    gameTurn = ?whenValueOf(#.gameId) is {
        'G-20': [C: [chosenCard: SushiGoCard.Pudding, chopsticksExchange: NoChopsticksExchange[]]],
        'G-21': [
            B: [chosenCard: SushiGoCard.MakiRoll2, chopsticksExchange: NoChopsticksExchange[]],
            C: [chosenCard: SushiGoCard.Pudding, chopsticksExchange: NoChopsticksExchange[]]
        ],
        'G-22': [
            B: [chosenCard: SushiGoCard.MakiRoll2, chopsticksExchange: NoChopsticksExchange[]],
            C: [chosenCard: SushiGoCard.Pudding, chopsticksExchange: NoChopsticksExchange[]]
        ],
        'G-23': [
            B: [chosenCard: SushiGoCard.MakiRoll2, chopsticksExchange: NoChopsticksExchange[]],
            C: [chosenCard: SushiGoCard.Pudding, chopsticksExchange: NoChopsticksExchange[]]
        ],
        ~: [:]
    };
    activeRound = ?whenValueOf(#.gameId) is {
        'G-20': ActiveRound[
            playerList: #.players,
            openCards: PlayersCards[
                A: [SushiGoCard.Chopsticks, SushiGoCard.MakiRoll1, SushiGoCard.Dumpling],
                B: [SushiGoCard.MakiRoll3, SushiGoCard.Sashimi, SushiGoCard.Wasabi],
                C: [SushiGoCard.MakiRoll2, SushiGoCard.NigiriEgg, SushiGoCard.NigiriSalmon]
            ],
            hiddenCards: PlayersCards[
                A: [SushiGoCard.NigiriSalmon, SushiGoCard.Tempura, SushiGoCard.Dumpling],
                B: [SushiGoCard.Tempura, SushiGoCard.MakiRoll2, SushiGoCard.Wasabi],
                C: [SushiGoCard.Pudding, SushiGoCard.Chopsticks, SushiGoCard.Dumpling]
            ]
        ],
        'G-21': ActiveRound[
            playerList: #.players,
            openCards: PlayersCards[
                A: [SushiGoCard.Chopsticks, SushiGoCard.MakiRoll1, SushiGoCard.Dumpling],
                B: [SushiGoCard.MakiRoll3, SushiGoCard.Sashimi, SushiGoCard.Wasabi],
                C: [SushiGoCard.MakiRoll2, SushiGoCard.NigiriEgg, SushiGoCard.NigiriSalmon]
            ],
            hiddenCards: PlayersCards[
                A: [SushiGoCard.NigiriSalmon, SushiGoCard.Tempura, SushiGoCard.Dumpling],
                B: [SushiGoCard.Tempura, SushiGoCard.MakiRoll2, SushiGoCard.Wasabi],
                C: [SushiGoCard.Pudding, SushiGoCard.Chopsticks, SushiGoCard.Dumpling]
            ]
        ],
        'G-22': ActiveRound[
            playerList: #.players,
            openCards: PlayersCards[
                A: [SushiGoCard.Chopsticks, SushiGoCard.MakiRoll1, SushiGoCard.Dumpling],
                B: [SushiGoCard.MakiRoll3, SushiGoCard.Sashimi, SushiGoCard.Wasabi],
                C: [SushiGoCard.MakiRoll2, SushiGoCard.NigiriEgg, SushiGoCard.NigiriSalmon]
            ],
            hiddenCards: PlayersCards[
                A: [SushiGoCard.NigiriSalmon],
                B: [SushiGoCard.MakiRoll2],
                C: [SushiGoCard.Pudding]
            ]
        ],
        'G-23': ActiveRound[
            playerList: #.players,
            openCards: PlayersCards[
                A: [SushiGoCard.Chopsticks, SushiGoCard.MakiRoll1, SushiGoCard.Dumpling],
                B: [SushiGoCard.MakiRoll3, SushiGoCard.Sashimi, SushiGoCard.Wasabi],
                C: [SushiGoCard.MakiRoll2, SushiGoCard.NigiriEgg, SushiGoCard.NigiriSalmon]
            ],
            hiddenCards: PlayersCards[
                A: [SushiGoCard.NigiriSalmon],
                B: [SushiGoCard.MakiRoll2],
                C: [SushiGoCard.Pudding]
            ]
        ],
        ~: ActiveRound[playerList: #.players, openCards: PlayersCards(#.players
            ->playerIds->flipMap(^PlayerId => Array<Nothing, 0..0> :: [])), hiddenCards: cards]
    };

    /* End TEMP */

    state = Mutable[type{ActiveGameState}, [
        activeRound: activeRound,
        completedRounds: completedRounds,
        gameTurn: gameTurn
    ]];
    [
        gameId: #.gameId,
        tableNumber: #.tableNumber,
        players: #.players,
        state: state,
        remainingDeck: deck
    ]
};

ActiveGame->gameId(^Null => GameId) :: $.gameId;
ActiveGame->players(^Null => Array<Player, 2..5>) :: $.players->players;
ActiveGame->activeRound(^Null => ActiveRound) :: $.state->value.activeRound;
ActiveGame->playMove(^[~PlayerId, ~PlayerMove] => Result<ActiveGame|CompletedGame, UnknownPlayer|SushiGoCardNotInHand|PlayerAlreadyMoved>) :: {
    playerId = #.playerId;
    playerMove = #.playerMove;

    player = ?noError($.players->playerWithId[playerId: #.playerId]);
    existingMove = $.state->value.gameTurn->item(#.playerId);

    checkEndOfRound = ^Null => ActiveGame|CompletedGame :: {
        remainingCards = $.state->value.activeRound->hiddenCards->cards->map(^Array => Integer :: #->length)->values->sum;
        ?whenValueOf(remainingCards) is {
            0: {
                completedRounds = $.state->value.completedRounds->insertLast($.state->value.activeRound->openCards);
                /*'end of round'->DUMPNL; completedRounds->length->DUMPNL;*/
                ?whenTypeOf(completedRounds) is {
                    type{Array<PlayersCards, 3..3>}: {
                        completedGame = CompletedGame[
                            gameId: $.gameId,
                            tableNumber: $.tableNumber,
                            players: $.players,
                            completedGameRounds: CompletedGameRounds[
                                playerList: $.players,
                                cardsByRound: completedRounds,
                                remainingDeck: $.remainingDeck
                            ]
                        ]
                        /*;'end of game'->DUMPNL; completedGame->DUMPNL*/
                    },
                    type{Array<PlayersCards, ..2>}: {
                        cards = $.remainingDeck->dealCards($.players);
                        ?whenTypeOf(cards) is {
                            type{PlayersCards}: {
                                activeRound = ActiveRound[playerList: $.players, openCards: PlayersCards($.players
                                    ->playerIds->flipMap(^PlayerId => Array<Nothing, 0..0> :: [])), hiddenCards: cards];
                                $.state->SET[
                                    completedRounds: completedRounds,
                                    activeRound: activeRound,
                                    gameTurn: [:]
                                ];
                                $
                            },
                            ~: $ /* TODO */
                        }
                    },
                    ~: $ /* TODO */
                }
            },
            ~: $
        }
    };
    checkEndOfTurn = ^Null => ActiveGame|CompletedGame :: {
        turnsCount = $.state->value.gameTurn->length;
        playersCount = $.players->players->length;
        checkEndOfRound(null); /* TEMP */
        ?whenIsTrue {
            turnsCount == playersCount: {
                activeRound = $.state->value.activeRound->applyPlayerMoves($.state->value.gameTurn);
                /*'end of turn'->DUMPNL; activeRound->DUMPNL;*/
                ?whenTypeOf(activeRound) is {
                    type{ActiveRound}: {
                        $.state->SET[
                            completedRounds: $.state->value.completedRounds,
                            activeRound: activeRound,
                            gameTurn: [:]
                        ];
                        checkEndOfRound(null)
                    },
                    ~: $
                }
            },
            ~: $
        }
    };
    doMove = ^Null => ActiveGame|CompletedGame :: {
        $.state->SET[
            completedRounds: $.state->value.completedRounds,
            activeRound: $.state->value.activeRound,
            gameTurn: $.state->value.gameTurn->withKeyValue[key: playerId, value: playerMove]
        ];
        checkEndOfTurn(null)
    };

    t = ?whenTypeOf(existingMove) is {
        type{PlayerMove}: Error(PlayerAlreadyMoved[]),
        ~: {
            playerCards = $.state->value.activeRound->hiddenCards->cards->item(#.playerId);
            ?whenTypeOf(playerCards) is {
                type{PlayerCards}: {
                    chosenCard = #.playerMove.chosenCard;
                    withoutChosenCard = playerCards->without(chosenCard);
                    ?whenTypeOf(withoutChosenCard) is {
                        type{PlayerCards}: {
                            chopsticksExchange = #.playerMove.chopsticksExchange;
                            ?whenTypeOf(chopsticksExchange) is {
                                type{SushiGoCard}: {
                                    withoutChopsticksExchangeCard = withoutChosenCard->without(chopsticksExchange);
                                    ?whenTypeOf(withoutChopsticksExchangeCard) is {
                                        type{PlayerCards}: {
                                            playerOpenCards = $.state->value.activeRound->openCards->cards->item(#.playerId);
                                            ?whenTypeOf(playerOpenCards) is {
                                                type{PlayerCards}: {
                                                    playerOpenCardsWithoutChopsticks = playerOpenCards->without(SushiGoCard.Chopsticks);
                                                    ?whenTypeOf(playerOpenCardsWithoutChopsticks) is {
                                                        type{PlayerCards}: doMove(),
                                                        ~: Error(SushiGoCardNotInHand[SushiGoCard.Chopsticks])
                                                    }
                                                },
                                                ~: Error(SushiGoCardNotInHand[SushiGoCard.Chopsticks])
                                            }
                                        },
                                        ~: Error(SushiGoCardNotInHand[chopsticksExchange])
                                    }
                                },
                                ~: doMove()
                            }
                        },
                        ~: Error(SushiGoCardNotInHand[chosenCard])
                    }
                },
                ~: Error(UnknownPlayer[playerId: #.playerId])
            }
        }
    }
};

CompletedGame->gameId(^Null => GameId) :: $.gameId;
CompletedGame->tableNumber(^Null => TableNumber) :: $.tableNumber;

TablePlayerList(Map<Player, ..5>) :: [players: Mutable[type{Map<Player, ..5>}, #]];
TablePlayerList->players(^Null => Map<Player, ..5>) :: $.players->value;
TablePlayerList->playerIds(^Null => Array<PlayerId, ..5>) :: $.players->value->map(^Player => PlayerId :: #.playerId)->values;
TablePlayerList->playerNames(^Null => Array<PlayerId, ..5>) :: $.players->value->map(^Player => PlayerName :: #.name)->values;
TablePlayerList->playerJoin(^[~PlayerName] => Result<PlayerId, TooManyPlayers|PlayerAlreadyOnTable>) %% [~Random] :: {
    players = $.players->value;
    ?whenTypeOf(players) is {
        type{Map<Player, ..4>}: ?whenIsTrue {
            $->playerNames->contains(#.playerName): Error(PlayerAlreadyOnTable[]),
            ~: {
                playerId = %.random->uuid;
                $.players->SET(players->withKeyValue[key: playerId, value: [playerId: playerId, name: #.playerName]]);
                playerId
            }
        },
        ~: Error(TooManyPlayers[])
    }
};
TablePlayerList->playerLeave(^[~PlayerId] => Result<Null, UnknownPlayer>) :: {
    players = $.players->value;
    withoutPlayer = players->withoutByKey(#.playerId);
    ?whenTypeOf(withoutPlayer) is {
        type{[element: Player, map: Map<Player, ..4>]}: {
            $.players->SET(withoutPlayer.map);
            null
        },
        ~: Error(UnknownPlayer(#))
    }
};

PlayroomTable[~TableNumber, ~PlayersCountRange] :: {
    /* TEMP mock */
    players20 = [A: [playerId: 'A', name: 'Player A'], B: [playerId: 'B', name: 'Player B'], C: [playerId: 'C', name: 'Player C']];
    players = ?whenValueOf(#.tableNumber) is {
        14: [A: [playerId: 'A', name: 'Player A'], B: [playerId: 'B', name: 'Player B']],
        20: players20,
        21: players20,
        22: players20,
        23: players20,
        98: [A: [playerId: 'A', name: 'Player A'], B: [playerId: 'B', name: 'Player B'], C: [playerId: 'C', name: 'Player C'], D: [playerId: 'D', name: 'Player D']],
        99: [A: [playerId: 'A', name: 'Player A'], B: [playerId: 'B', name: 'Player B'], C: [playerId: 'C', name: 'Player C'], D: [playerId: 'D', name: 'Player D'], E: [playerId: 'E', name: 'Player E']],
        ~: [:]
    };
    game = ?whenValueOf(#.tableNumber) is {
        20: ActiveGame[gameId: 'G-20', tableNumber: 20, players: GamePlayerList(players20->values)],
        21: ActiveGame[gameId: 'G-21', tableNumber: 21, players: GamePlayerList(players20->values)],
        22: ActiveGame[gameId: 'G-22', tableNumber: 22, players: GamePlayerList(players20->values)],
        23: ActiveGame[gameId: 'G-23', tableNumber: 23, players: GamePlayerList(players20->values)],
        ~: NoActiveGame[]
    };
    [
        tableNumber: #.tableNumber,
        playersCountRange: #.playersCountRange,
        players: TablePlayerList(players),
        activeGame: Mutable[type{NoActiveGame|ActiveGame}, game]
    ]
};
PlayroomTable->number(^Null => TableNumber) :: $.tableNumber;
PlayroomTable->startGame(^Null => Result<ActiveGame, NotEnoughPlayers|GameAlreadyInProgress>) %% [~Random] :: {
    activeGame = $.activeGame->value;
    ?whenTypeOf(activeGame) is {
        type{ActiveGame}: Error(GameAlreadyInProgress[]),
        type{NoActiveGame}: {
            players = $.players->players;
            ?whenTypeOf(players) is {
                type{Map<Player, 2..5>}: {
                    playersCount = players->length;
                    ?whenIsTrue {
                        playersCount < $.playersCountRange.minPlayers: Error(NotEnoughPlayers[]),
                        ~: {
                            gameId = %.random->uuid;
                            game = ActiveGame[gameId: gameId, tableNumber: $.tableNumber, players: GamePlayerList(players->values)];
                            $.activeGame->SET(game);
                            game
                        }
                    }
                },
                ~: Error(NotEnoughPlayers[])
            }
        }
    }
};
PlayroomTable->activeGame(^Null => NoActiveGame|ActiveGame) :: $.activeGame->value;
PlayroomTable->markActiveGameAsCompleted(^Null => Null) :: {
    $.activeGame->SET(NoActiveGame[]);
    null
};

PlayroomTable->playerJoin(^[~PlayerName] => Result<PlayerId, TooManyPlayers|PlayerAlreadyOnTable|GameAlreadyInProgress>) :: {
    players = $.players->players;
    ?whenIsTrue {
        {players->length} == $.playersCountRange.maxPlayers: Error(TooManyPlayers[]),
        $.activeGame->value->isOfType(type{ActiveGame}): Error(GameAlreadyInProgress[]),
        ~: ?noError($.players->playerJoin(#))
    }
};

PlayroomTable->playerLeave(^[~PlayerId] => Result<Null, UnknownPlayer|GameAlreadyInProgress>) :: {
    game = $.activeGame->value;
    ?whenTypeOf(game) is {
        type{ActiveGame}: Error(GameAlreadyInProgress[]),
        ~: ?noError($.players->playerLeave(#))
    }
};

PlayroomTables(Null) :: {
    range = PlayersCountRange[minPlayers: 3, maxPlayers: 5];
    range4 = PlayersCountRange[minPlayers: 3, maxPlayers: 4];
    /* TEMP mock */
    ?whenTypeOf(range) is {
        type{PlayersCountRange}: {
            ?whenTypeOf(range4) is {
                type{PlayersCountRange}: {
                    table14 = PlayroomTable[tableNumber: 14, playersCountRange: range];
                    table20 = PlayroomTable[tableNumber: 20, playersCountRange: range];
                    table21 = PlayroomTable[tableNumber: 21, playersCountRange: range];
                    table22 = PlayroomTable[tableNumber: 22, playersCountRange: range];
                    table23 = PlayroomTable[tableNumber: 23, playersCountRange: range];
                    table98 = PlayroomTable[tableNumber: 98, playersCountRange: range4];
                    table99 = PlayroomTable[tableNumber: 99, playersCountRange: range];
                    [
                        tables: Mutable[type{Map<PlayroomTable>},
                            {{{{{{[:]
                            ->withKeyValue[key: '14', value: table14]}
                            ->withKeyValue[key: '20', value: table20]}
                            ->withKeyValue[key: '21', value: table21]}
                            ->withKeyValue[key: '22', value: table22]}
                            ->withKeyValue[key: '23', value: table23]}
                            ->withKeyValue[key: '98', value: table98]}
                            ->withKeyValue[key: '99', value: table99]
                        ]
                    ]
                },
                ~: [tables: Mutable[type{Map<PlayroomTable>}, [:]]]
            }
        },
         ~: [tables: Mutable[type{Map<PlayroomTable>}, [:]]]
    }
};
PlayroomTables->all(^Null => Array<PlayroomTable>) :: $.tables->value->values;
PlayroomTables->new(^[playersCount: PlayersCountRange] => PlayroomTable) %% [~Random] :: {
    random = %.random;
    takeFreeTableNumber = ^Null => TableNumber :: {
        tableNumber = random->integer[min: 1, max: 999];
        ?whenIsTrue {
            $.tables->value->keyExists(tableNumber->asString): takeFreeTableNumber(null),
            ~: tableNumber
        }
    };
    tableNumber = takeFreeTableNumber(null);
    existingTable = $.tables->value->item(tableNumber->asString);
    newTable = PlayroomTable[tableNumber: tableNumber, playersCountRange: #.playersCount];
    $.tables->SET(
        $.tables->value->withKeyValue[key: tableNumber->asString, value: newTable]
    );
    newTable
};
PlayroomTables->withNumber(^[~TableNumber] => Result<PlayroomTable, UnknownTable>) :: {
    table = $.tables->value->item(#.tableNumber->asString);
    ?whenTypeOf(table) is {
        type{PlayroomTable}: table,
        ~: Error(UnknownTable(#))
    }
};


PlayroomGames(Null) %% [~SushiGoFullDeck] :: {
    deck = %.sushiGoFullDeck->shuffle;

    /* TEMP mock */
    c = [A: [SushiGoCard.Tempura], B: [SushiGoCard.Sashimi], C: [SushiGoCard.Dumpling]];
    p = GamePlayerList[[playerId: 'A', name: 'Player A'], [playerId: 'B', name: 'Player B'], [playerId: 'C', name: 'Player C']];
    games = {{{{[:]->withKeyValue[key: 'G-20', value: ActiveGame[gameId: 'G-20', tableNumber: 20, players: p]]}
                   ->withKeyValue[key: 'G-21', value: ActiveGame[gameId: 'G-21', tableNumber: 21, players: p]]}
                   ->withKeyValue[key: 'G-22', value: ActiveGame[gameId: 'G-22', tableNumber: 22, players: p]]}
                   ->withKeyValue[key: 'G-23', value: ActiveGame[gameId: 'G-23', tableNumber: 23, players: p]]}
        ->withKeyValue[key: 'G-3', value: CompletedGame[gameId: 'G-3', tableNumber: 3, players: p, completedGameRounds: CompletedGameRounds[
            playerList: p, cardsByRound: [PlayersCards(c), PlayersCards(c), PlayersCards(c)], remainingDeck: deck
        ]]];
    [games: Mutable[type{Map<PlayroomGame>}, games]]
};

PlayroomGames->all(^Null => Array<PlayroomGame>) :: $.games->value->values;
PlayroomGames->withId(^[~GameId] => Result<PlayroomGame, UnknownGame>) :: {
    game = $.games->value->item(#.gameId);
    ?whenTypeOf(game) is {
        type{PlayroomGame}: game,
        ~: Error(UnknownGame(#))
    }
};
PlayroomGames->add(^[~ActiveGame] => ActiveGame) :: {
    $.games->SET(
        $.games->value->withKeyValue[key: #.activeGame->gameId, value: #.activeGame]
    );
    #.activeGame
};
PlayroomGames->markAsCompleted(^[~CompletedGame] => CompletedGame) :: {
    $.games->SET(
        $.games->value->withKeyValue[key: #.completedGame->gameId, value: #.completedGame]
    );
    #.completedGame
};



Playroom(Null) :: [tables: PlayroomTables(null), games: PlayroomGames(null)];
Playroom->tables(^Null => PlayroomTables) :: $.tables;
Playroom->games(^Null => PlayroomGames) :: $.games;
Playroom->startGame(^[~TableNumber] => Result<ActiveGame, UnknownTable|NotEnoughPlayers|GameAlreadyInProgress>) :: {
    game = ?noError(?noError($.tables->withNumber(#))->startGame);
    $.games->add[activeGame: game];
    game
};
Playroom->markGameAsCompleted(^[~CompletedGame] => CompletedGame) :: {
    $.games->markAsCompleted(#);
    table = $.tables->withNumber[tableNumber: #.completedGame->tableNumber];
    ?whenTypeOf(table) is {
        type{PlayroomTable}: table->markActiveGameAsCompleted, /* TODO - error handling */
        ~: null
    };
    #.completedGame
};
