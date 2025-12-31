<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;

Route::get('/', function () {
    return view('welcome');
});


Route::get('/blog/{heading}', function ($heading) {

    $heading = trim(urldecode($heading));

    $blog = DB::table('blogs')
        ->select('content')
        ->whereRaw('LOWER(heading) = ?', [strtolower($heading)])
        ->first();

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

    $blog = DB::table('updatedblogs')
        ->select('content')
        ->whereRaw('LOWER(heading) = ?', [strtolower($heading)])
        ->first();

    if (!$blog) {
        return response()->json([
            'message' => 'Updated blog not found'
        ], 404);
    }

    return response()->json($blog);
})
->where('heading', '.*');
