#!/usr/bin/env php
<?php

use Walnut\Lang\Blueprint\Compilation\Source;
use Walnut\Lang\Implementation\Registry\ProgramBuilderFactory;
use Walnut\Lang\Implementation\Compilation\ProgramCompilationContext;
use Walnut\Lang\NativeConnector\SwooleHttp\Implementation\SwooleHttpProgramCompilerAdapter;

require_once __DIR__ . '/vendor/autoload.php';
$sourceRoot = __DIR__ . '/walnut-src';

foreach(glob("$sourceRoot/*.nut") as $sourceFile) {
	$sources[] = str_replace('.nut', '', basename($sourceFile));
}
$source = 'sushi-go-main';
$program = (new SwooleHttpProgramCompilerAdapter(
    new ProgramCompilationContext(
        new ProgramBuilderFactory()
    )
))->compileHttpProgram(
	new Source($sourceRoot, $source)
);

$http = new Swoole\Http\Server("0.0.0.0", 9501);
$http->on(
    "request",
    function (Swoole\Http\Request $request, Swoole\Http\Response $response) use ($program) {
	    try {
			$program->execute($request, $response);
			$response->end();
			return;
	    } catch (Throwable $e) {
		    $response->end((string)$e);
			return;
	    }
    }
);
$http->start();