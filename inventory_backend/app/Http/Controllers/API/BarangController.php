<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Barang;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class BarangController extends Controller
{
    public function index(Request $request)
    {
        $me = $request->user();
        if (!$me) return response()->json(['message' => 'Unauthorized'], 403);

        $items = Barang::with('supplier')->get();
        // map to friendly keys
        $data = $items->map(function ($i) {
            return [
                'id' => $i->id,
                'nama_barang' => $i->nama_barang,
                'id_supplier' => $i->id_supplier,
                'supplier_name' => $i->supplier?->nama_supplier,
                'id_kategori' => $i->id_kategori,
                'kategori_name' => $i->kategori?->nama_kategori,
                'stok' => $i->stok,
                'satuan' => $i->satuan,
                'lokasi' => $i->lokasi ?? null,
                'harga' => $i->harga,
                'created_at' => $i->created_at,
            ];
        });
        return response()->json($data);
    }

    public function show(Request $request, $id)
    {
        $me = $request->user();
        if (!$me) return response()->json(['message' => 'Unauthorized'], 403);

        $i = Barang::with('supplier')->find($id);
        if (!$i) return response()->json(['message' => 'Not found'], 404);
        return response()->json($i);
    }

    public function store(Request $request)
    {
        $me = $request->user();
        if (!$me || ($me->role ?? '') !== 'admin') return response()->json(['message' => 'Unauthorized'], 403);

        $data = $request->only(['nama_barang', 'id_kategori', 'id_supplier', 'stok', 'satuan', 'harga', 'kode_barang', 'lokasi']);
        $validator = Validator::make($data, [
            'nama_barang' => 'required',
            'id_supplier' => 'required|exists:supplier,id',
            'stok' => 'required|numeric',
            'satuan' => 'nullable',
            'harga' => 'nullable|numeric',
            'lokasi' => 'nullable|string|max:255',
        ]);
        if ($validator->fails()) return response()->json(['errors' => $validator->errors()], 422);

        // ensure kode_barang exists (table requires it)
        if (empty($data['kode_barang'])) {
            $data['kode_barang'] = 'BRG' . strtoupper(substr(uniqid(), -6));
        }

        // id_kategori is optional now (nullable); frontend should send it when available

        $item = Barang::create($data);
        return response()->json(['message' => 'Item created', 'item' => $item], 201);
    }

    public function update(Request $request, $id)
    {
        $me = $request->user();
        if (!$me || ($me->role ?? '') !== 'admin') return response()->json(['message' => 'Unauthorized'], 403);

        $item = Barang::find($id);
        if (!$item) return response()->json(['message' => 'Not found'], 404);

        $data = $request->only(['nama_barang', 'id_supplier', 'stok', 'satuan', 'harga', 'lokasi']);
        $validator = Validator::make($data, [
            'nama_barang' => 'sometimes|required',
            'id_supplier' => 'sometimes|required|exists:supplier,id',
            'stok' => 'sometimes|required|numeric',
            'satuan' => 'nullable',
            'harga' => 'nullable|numeric',
            'lokasi' => 'nullable|string|max:255',
        ]);
        if ($validator->fails()) return response()->json(['errors' => $validator->errors()], 422);

        $item->fill($data);
        $item->save();

        return response()->json(['message' => 'Item updated', 'item' => $item]);
    }

    public function destroy(Request $request, $id)
    {
        $me = $request->user();
        if (!$me || ($me->role ?? '') !== 'admin') return response()->json(['message' => 'Unauthorized'], 403);

        $item = Barang::find($id);
        if (!$item) return response()->json(['message' => 'Not found'], 404);

        $item->delete();
        return response()->json(['message' => 'Item deleted']);
    }
}
