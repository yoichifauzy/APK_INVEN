<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Kategori;
use Illuminate\Http\Request;

class KategoriController extends Controller
{
    public function index(Request $request)
    {
        $me = $request->user();
        if (!$me) return response()->json(['message' => 'Unauthorized'], 403);

        $cats = Kategori::orderBy('nama_kategori')->get();
        return response()->json($cats);
    }
}
