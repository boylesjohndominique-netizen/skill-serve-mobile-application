<?php

declare(strict_types=1);

// Generates readable module files from the backend's implementation-generated OpenAPI document.
$root = dirname(__DIR__);
$specPath = $root . '/backend/storage/api-docs/api-docs.json';
$outputPath = __DIR__ . '/modules';

if (! is_file($specPath)) {
    fwrite(STDERR, "OpenAPI source not found: {$specPath}\n");
    exit(1);
}

$spec = json_decode((string) file_get_contents($specPath), true, 512, JSON_THROW_ON_ERROR);
copy($specPath, __DIR__ . '/openapi.json');
if (! is_dir($outputPath)) {
    mkdir($outputPath, 0775, true);
}

$methods = ['get', 'post', 'put', 'patch', 'delete'];
$modules = [];
$routeMethods = [];
$routeList = shell_exec('cd ' . escapeshellarg($root . '/backend') . ' && php artisan route:list --path=api --except-vendor --json 2>/dev/null');
if (is_string($routeList) && $routeList !== '') {
    foreach (json_decode($routeList, true) ?? [] as $route) {
        $uri = '/' . ltrim(str_replace('\\/', '/', (string) ($route['uri'] ?? '')), '/');
        foreach (explode('|', (string) ($route['method'] ?? '')) as $routeMethod) {
            $routeMethod = strtolower($routeMethod);
            if (in_array($routeMethod, $methods, true)) {
                $routeMethods[$uri][$routeMethod] = true;
            }
        }
    }
}

foreach ($spec['paths'] as $path => $pathItem) {
    foreach ($methods as $method) {
        if (! isset($pathItem[$method])) {
            continue;
        }
        $operation = $pathItem[$method];
        $tag = $operation['tags'][0] ?? 'Uncategorized';
        $modules[$tag][] = [$path, strtoupper($method), $operation];

        // Swagger has one operation for update aliases, while Laravel exposes both.
        if ($method === 'put' && isset($routeMethods[$path]['patch']) && ! isset($pathItem['patch'])) {
            $modules[$tag][] = [$path, 'PATCH', $operation];
        }
    }
}

$moduleNames = [];
foreach ($modules as $tag => $operations) {
    usort($operations, static fn (array $a, array $b): int => [$a[0], $a[1]] <=> [$b[0], $b[1]]);
    $filename = strtolower((string) preg_replace('/[^a-z0-9]+/i', '-', $tag));
    $moduleNames[$tag] = $filename . '.md';
    $markdown = "# {$tag}\n\n";
    $markdown .= "All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.\n\n";

    foreach ($operations as [$path, $method, $operation]) {
        $markdown .= "## `{$method} {$path}`\n\n";
        $markdown .= ($operation['description'] ?? $operation['summary'] ?? 'Implemented API operation.') . "\n\n";
        $markdown .= '**Authentication:** ' . (isset($operation['security']) ? 'Bearer token' : 'Public') . "\n\n";

        $parameters = $operation['parameters'] ?? [];
        $markdown .= "### Parameters\n\n";
        if ($parameters === []) {
            $markdown .= "None.\n\n";
        } else {
            $markdown .= "| Name | Location | Required | Type / allowed values |\n|---|---|---:|---|\n";
            foreach ($parameters as $parameter) {
                $schema = $parameter['schema'] ?? [];
                $type = $schema['type'] ?? 'object';
                if (isset($schema['enum'])) {
                    $type .= ' (`' . implode('`, `', $schema['enum']) . '`)';
                }
                $markdown .= '| `' . ($parameter['name'] ?? '') . '` | ' . ($parameter['in'] ?? '') . ' | ' . (($parameter['required'] ?? false) ? 'yes' : 'no') . ' | ' . $type . " |\n";
            }
            $markdown .= "\n";
        }

        $body = $operation['requestBody']['content']['application/json'] ?? null;
        $markdown .= "### Request body and validation\n\n";
        if ($body === null) {
            $markdown .= "No JSON request body.\n\n";
        } else {
            $schema = $body['schema'] ?? [];
            $required = $schema['required'] ?? [];
            $properties = $schema['properties'] ?? [];
            if ($properties !== []) {
                $markdown .= "| Field | Required | Validation / type |\n|---|---:|---|\n";
                foreach ($properties as $name => $property) {
                    $details = $property['type'] ?? 'object';
                    foreach (['format', 'minLength', 'maxLength', 'minimum', 'maximum'] as $key) {
                        if (isset($property[$key])) {
                            $details .= ', ' . $key . '=' . $property[$key];
                        }
                    }
                    if (isset($property['enum'])) {
                        $details .= ', one of: `' . implode('`, `', $property['enum']) . '`';
                    }
                    $markdown .= '| `' . $name . '` | ' . (in_array($name, $required, true) ? 'yes' : 'no') . ' | ' . $details . " |\n";
                }
                $markdown .= "\n";
            } else {
                $markdown .= "See the request schema in `openapi.json`.\n\n";
            }
            if (isset($body['example'])) {
                $markdown .= "Example request body:\n\n```json\n" . json_encode($body['example'], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n```\n\n";
            }
        }

        $markdown .= "### Responses\n\n";
        foreach ($operation['responses'] ?? [] as $status => $response) {
            $markdown .= "#### HTTP {$status}: " . ($response['description'] ?? '') . "\n\n";
            $example = $response['content']['application/json']['example'] ?? null;
            if ($example !== null) {
                $markdown .= "```json\n" . json_encode($example, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n```\n\n";
            } else {
                $markdown .= "Response schema: `" . (($response['content']['application/json']['schema']['$ref'] ?? 'see openapi.json')) . "`\n\n";
            }
        }
    }

    file_put_contents($outputPath . '/' . $moduleNames[$tag], $markdown);
}

ksort($moduleNames);
$index = "# API Modules\n\n";
foreach ($moduleNames as $tag => $file) {
    $index .= "- [{$tag}](modules/{$file})\n";
}
file_put_contents(__DIR__ . '/MODULES.md', $index);

echo 'Generated ' . count($moduleNames) . " module files.\n";
