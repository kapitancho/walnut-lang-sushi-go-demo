module sushi-go-config %% sushi-go-model, sushi-go-http, http-middleware:

==> Playroom :: Playroom(null);

==> LookupRouterMapping :: [
    [path: '/playroom', type: type{SushiGoHttpHandler}]
];

==> CompositeHandler %% [
    defaultHandler: NotFoundHandler,
    ~LookupRouter,
    ~CorsMiddleware
] :: CompositeHandler[
    defaultHandler: %.defaultHandler->as(type{HttpRequestHandler}),
    middlewares: [
        %.corsMiddleware->as(type{HttpMiddleware}),
        %.lookupRouter->as(type{HttpMiddleware})
    ]
];
