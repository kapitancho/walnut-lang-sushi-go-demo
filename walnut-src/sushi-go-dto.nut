module sushi-go-dto %% sushi-go-model:

NoCard = Null;
CardName = String<6..14>;
PlayerCardList = Array<CardName, ..10>;
CompletedGameRoundData = [cards: Map<PlayerCardList>];
ActiveGameRoundData = [openCards: Map<PlayerCardList>];
PlayerActiveGameRoundData = [openCards: Map<PlayerCardList>, playerHiddenCards: PlayerCardList];

NewTableData = [~PlayersCountRange];

TableAdded = $[~TableNumber];
PlayerData = [~PlayerName];
PlayerJoined = $[~TableNumber, ~PlayerId];
PlayerLeft = $[~TableNumber, ~PlayerId];
GameStarted = $[~TableNumber, ~GameId];

UnknownCard = $[~CardName];
CardNotInHand = $[~CardName];

PlayerCardMove = [chosenCard: CardName, chopsticksExchange: NoCard|CardName];

ActiveGameData = [id: GameId, players: Array<PlayerName>, completedRounds: Array<CompletedGameRoundData, ..2>, activeRound: ActiveGameRoundData];
PlayerGameData = [id: GameId, players: Array<PlayerName>, completedRounds: Array<CompletedGameRoundData, ..2>, playerActiveRound: PlayerActiveGameRoundData];
CompletedGameData = [id: GameId, players: Array<PlayerName>, completedRounds: Array<CompletedGameRoundData, 3..3>];
GameData = ActiveGameData|CompletedGameData;
TableData = [number: TableNumber, joinedPlayers: Integer<0..5>, playersCount: PlayersCountRange, currentGame: NoActiveGame|ActiveGameData];

ListPlayroomTables = ^[:] => Array<TableData>;
PlayroomTableByTableNumber = ^[~TableNumber] => Result<TableData, UnknownTable>;
NewTable = ^[~NewTableData] => TableAdded;
PlayerJoinTable = ^[~TableNumber, ~PlayerData] => Result<PlayerJoined, UnknownTable|TooManyPlayers|PlayerAlreadyOnTable|GameAlreadyInProgress>;
PlayerLeaveTable = ^[~TableNumber, ~PlayerId] => Result<PlayerLeft, UnknownTable|UnknownPlayer|GameAlreadyInProgress>;
StartGame = ^[~TableNumber] => Result<GameStarted, UnknownTable|NotEnoughPlayers|GameAlreadyInProgress>;
CurrentGameOnTable = ^[~TableNumber] => Result<ActiveGameData, UnknownTable|NoActiveGame>;
ListPlayroomGames = ^[:] => Array<ActiveGameData|CompletedGameData>;
PlayroomGameById = ^[~GameId] => Result<ActiveGameData|CompletedGameData, UnknownGame>;
PlayerGame = ^[~GameId, ~PlayerId] => Result<PlayerGameData|CompletedGameData, UnknownGame|UnknownPlayer>;
PlayMove = ^[~GameId, ~PlayerId, ~PlayerCardMove] => Result<PlayerMoveAccepted, UnknownGame|UnknownPlayer|UnknownCard|CardNotInHand|PlayerAlreadyMoved|GameAlreadyCompleted>;

