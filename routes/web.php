<?php

use Illuminate\Support\Facades\Route;
use MongoDB\Client;
use MongoDB\BSON\Regex;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/blog/{heading}', function ($heading) {

    $heading = trim(urldecode($heading));

    $client = new Client(env('MONGODB_URI'));

    $blog = $client
        ->selectDatabase('blog')
        ->selectCollection('blogs')
        ->findOne(
            [
                'heading' => new Regex('^' . preg_quote($heading) . '$', 'i')
            ],
            [
                'projection' => [
                    '_id' => 0,
                    'content' => 1
                ]
            ]
        );

    if (!$blog) {
        return response()->json([
            'message' => 'Blog not found'
        ], 404);
    }

    return response()->json($blog);
})
->where('heading', '.*'); 

Route::get('/updated-blog/{heading}', function ($heading) {

    $heading = trim(urldecode($heading));

    $client = new Client(env('MONGODB_URI'));

    $blog = $client
        ->selectDatabase('blog')
        ->selectCollection('updatedblogs')
        ->findOne(
            [
                'heading' => new Regex('^' . preg_quote($heading) . '$', 'i')
            ],
            [
                'projection' => [
                    '_id' => 0,
                    'content' => 1
                ]
            ]
        );

    if (!$blog) {
        return response()->json(['message' => 'Updated blog not found'], 404);
    }

    return response()->json($blog);
})->where('heading', '.*');