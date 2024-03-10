module sushi-go-http %% http-core, http-route, http-response-helper, sushi-go-controller:

SushiGoHttpRouteChain = HttpRouteChain;

==> SushiGoHttpRouteChain ::
    HttpRouteChain[routes: [
        httpDelete          [RoutePattern('/tables/{+tableNumber}/players/{playerId}'), type{PlayerLeaveTable}],
        httpPostJsonLocation[RoutePattern('/tables/{+tableNumber}/players'), type{PlayerJoinTable}, 'playerData'],
        httpPostJsonLocation[RoutePattern('/tables/{+tableNumber}/game'), type{StartGame}, null],
        httpGetAsJson       [RoutePattern('/tables/{+tableNumber}/game'), type{CurrentGameOnTable}],
        httpGetAsJson       [RoutePattern('/tables/{+tableNumber}'), type{PlayroomTableByTableNumber}],
        httpGetAsJson       [RoutePattern('/tables'), type{ListPlayroomTables}],
        httpPostJsonLocation[RoutePattern('/tables'), type{NewTable}, 'newTableData'],

        httpPostJson        [RoutePattern('/games/{gameId}/players/{playerId}/card'), type{PlayMove}, 'playerCardMove'],
        httpGetAsJson       [RoutePattern('/games/{gameId}/players/{playerId}'), type{PlayerGame}],
        httpGetAsJson       [RoutePattern('/games/{gameId}'), type{PlayroomGameById}],
        httpGetAsJson       [RoutePattern('/games'), type{ListPlayroomGames}]
    ]];

SushiGoHttpHandler = :[];
SushiGoHttpHandler ==> HttpRequestHandler %% [~SushiGoHttpRouteChain] :: {
    sushiGoRouteChain = %.sushiGoHttpRouteChain;
    ^[request: HttpRequest] => Result<HttpResponse, Any> :: {
        request = #.request;
        response = ?whenTypeOf(sushiGoRouteChain) is {
            type{HttpRouteChain}: sushiGoRouteChain->handleRequest(request),
            ~: null
        };
        ?whenTypeOf(response) is {
            type{Result<Nothing, HttpRouteDoesNotMatch>}: notFound(request),
            type{HttpResponse}: response,
            ~: {
                [
                    statusCode: 200,
                    protocolVersion: HttpProtocolVersion.HTTP11,
                    headers: [:],
                    body: 'oops'
                ]
            }
        }
    }
};

InvalidJsonString ==> HttpResponse :: badRequest({'Invalid JSON body: '}->concat($->value));
HydrationError ==> HttpResponse :: badRequest({'Invalid request parameters: '}->concat($->errorMessage));
DependencyContainerError ==> HttpResponse :: internalServerError({'Handler error: '}->concatList[
    $->errorMessage, ': ', $->targetType->asString
]);
InvalidJsonValue ==> HttpResponse :: internalServerError({'Invalid handler result: '}->concat($.value->type->asString));
CastNotAvailable ==> HttpResponse :: internalServerError(''->concatList[
    'Type conversion failure: from type ', $.from->asString, ' to type ', $.to->asString
]);

NoActiveGame ==> JsonValue :: null;
NoActiveGame ==> HttpResponse :: notFound('No active game on this table');
UnknownTable ==> HttpResponse :: notFound({'Unknown table: '}->concat($.tableNumber->asString));
TableAdded ==> String :: '/playroom/tables/'->concat($.tableNumber->asString);
UnknownGame ==> HttpResponse :: notFound({'Unknown game: '}->concat($.gameId));
UnknownCard ==> HttpResponse :: conflict({'Unknown card: '}->concat($.cardName));
PlayerAlreadyMoved ==> HttpResponse :: conflict('Player already moved');
GameAlreadyCompleted ==> HttpResponse :: forbidden('Game already completed');
CardNotInHand ==> HttpResponse :: conflict({'Card not in hand: '}->concat($.cardName));
UnknownPlayer ==> HttpResponse :: notFound({'Unknown player: '}->concat($.playerId));
TooManyPlayers ==> HttpResponse :: conflict('Too many players');
PlayerAlreadyOnTable ==> HttpResponse :: conflict('Player with the same name is already on the table');
NotEnoughPlayers ==> HttpResponse :: conflict('Not enough players');
GameAlreadyInProgress ==> HttpResponse :: conflict('Game already in progress');
PlayerJoined ==> String :: ''->concatList['/playroom/tables/', $.tableNumber->asString, '/players/', $.playerId];
GameStarted ==> String :: ''->concatList['/playroom/games/', $.gameId];
