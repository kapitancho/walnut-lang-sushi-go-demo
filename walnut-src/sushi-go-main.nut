module sushi-go-main %% sushi-go-http, sushi-go-config, generic-http:

handleRequest = ^HttpRequest => HttpResponse :: {
    response = HttpServer[]->handleRequest(#);
    ?whenTypeOf(response) is {
        type{HttpResponse}: response,
        ~: [
           statusCode: 500,
           protocolVersion: HttpProtocolVersion.HTTP11,
           headers: [:],
           body: ''
       ]
    }
};

main = ^Array<String> => String :: {
    x = 'Compilation successful!';
    x->printed
};