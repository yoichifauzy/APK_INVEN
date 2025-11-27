<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\RequestBarang;
use Illuminate\Http\Request;

class TrackingController extends Controller
{
    public function tracking(Request $request)
    {
        return RequestBarang::where('id_user', $request->user()->id)
            ->with(['barang'])
            ->get();
    }
}
