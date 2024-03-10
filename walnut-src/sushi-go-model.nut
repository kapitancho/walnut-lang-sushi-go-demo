module sushi-go-model:

SushiGoCard = :[
    Tempura, Sashimi, Dumpling,
    MakiRoll3, MakiRoll2, MakiRoll1,
    NigiriSquid, NigiriSalmon, NigiriEgg,
    Pudding, Wasabi, Chopsticks
];

SushiGoCardArray = Array<SushiGoCard, ..168>;

SushiGoFullDeck = $[cards: SushiGoCardArray];
SushiGoShuffledDeck = $[cards: Mutable<SushiGoCardArray>];

NoChopsticksExchange = :[];
PlayerMove = [chosenCard: SushiGoCard, chopsticksExchange: NoChopsticksExchange|SushiGoCard];

PlayerId = String<1..>;
PlayerName = String<1..20>;
Player = [~PlayerId, name: PlayerName];
GamePlayerList = $[players: Array<Player, 2..5>];
UnknownPlayer = $[~PlayerId];

PlayerCards = Array<SushiGoCard, ..10>;
SushiGoCardNotInHand = $[~SushiGoCard];

PlayersCards = $[cards: Map<PlayerCards>];

ActiveRound = $[playerList: GamePlayerList, openCards: PlayersCards, hiddenCards: PlayersCards];
CompletedGameRounds = $[playerList: GamePlayerList, cardsByRound: Array<PlayersCards, 3..3>, remainingDeck: SushiGoShuffledDeck];

GameId = String<1..>;
UnknownGame = $[~GameId];
NoActiveGame = :[];

TableNumber = Integer<1..>;
UnknownTable = $[~TableNumber];

GameTurn = Map<PlayerMove>;

ActiveGameState = [completedRounds: Array<PlayersCards, ..2>, ~ActiveRound, ~GameTurn];
ActiveGame = $[~GameId, ~TableNumber, players: GamePlayerList, state: Mutable<ActiveGameState>, remainingDeck: SushiGoShuffledDeck];
CompletedGame = $[~GameId, ~TableNumber, players: GamePlayerList, ~CompletedGameRounds];

PlayersCount = Integer<2..5>;
InvalidPlayersCountRange = $[minPlayers: PlayersCount, maxPlayers: PlayersCount];
PlayersCountRange <: [minPlayers: PlayersCount, maxPlayers: PlayersCount] @ InvalidPlayersCountRange :: ?whenIsTrue {
    #.minPlayers > #.maxPlayers: Error(InvalidPlayersCountRange(#)), ~: null
};

TablePlayerList = $[players: Mutable<Map<Player, ..5>>];
PlayroomTable = $[~TableNumber, ~PlayersCountRange, players: TablePlayerList, activeGame: Mutable<NoActiveGame|ActiveGame>];
PlayroomTables = $[tables: Mutable<Map<PlayroomTable>>];
PlayroomGame = ActiveGame|CompletedGame;
PlayroomGames = $[games: Mutable<Map<PlayroomGame>>];
Playroom = $[tables: PlayroomTables, games: PlayroomGames];

PlayerAlreadyOnTable = :[];
NotEnoughPlayers = :[];
TooManyPlayers = :[];
GameAlreadyInProgress = :[];
PlayerAlreadyMoved = :[];
GameAlreadyCompleted = :[];
PlayerMoveAccepted = :[];


