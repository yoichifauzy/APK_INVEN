<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Supplier;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SupplierController extends Controller
{
    public function index(Request $request)
    {
        $me = $request->user();
        if (!$me) return response()->json(['message' => 'Unauthorized'], 403);

        $suppliers = Supplier::select('id', 'nama_supplier', 'kontak', 'alamat', 'created_at')->get();
        return response()->json($suppliers);
    }

    public function show(Request $request, $id)
    {
        $me = $request->user();
        if (!$me) return response()->json(['message' => 'Unauthorized'], 403);

        $supplier = Supplier::find($id);
        if (!$supplier) return response()->json(['message' => 'Not found'], 404);
        return response()->json($supplier);
    }

    public function store(Request $request)
    {
        $me = $request->user();
        if (!$me || ($me->role ?? '') !== 'admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $data = $request->only(['nama_supplier', 'kontak', 'alamat']);
        $validator = Validator::make($data, [
            'nama_supplier' => 'required',
            'kontak' => 'nullable',
            'alamat' => 'nullable',
        ]);
        if ($validator->fails()) return response()->json(['errors' => $validator->errors()], 422);

        $supplier = Supplier::create($data);
        return response()->json(['message' => 'Supplier created', 'supplier' => $supplier], 201);
    }

    public function update(Request $request, $id)
    {
        $me = $request->user();
        if (!$me || ($me->role ?? '') !== 'admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $supplier = Supplier::find($id);
        if (!$supplier) return response()->json(['message' => 'Not found'], 404);

        $data = $request->only(['nama_supplier', 'kontak', 'alamat']);
        $validator = Validator::make($data, [
            'nama_supplier' => 'sometimes|required',
            'kontak' => 'nullable',
            'alamat' => 'nullable',
        ]);
        if ($validator->fails()) return response()->json(['errors' => $validator->errors()], 422);

        $supplier->fill($data);
        $supplier->save();

        return response()->json(['message' => 'Supplier updated', 'supplier' => $supplier]);
    }

    public function destroy(Request $request, $id)
    {
        $me = $request->user();
        if (!$me || ($me->role ?? '') !== 'admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $supplier = Supplier::find($id);
        if (!$supplier) return response()->json(['message' => 'Not found'], 404);

        $supplier->delete();
        return response()->json(['message' => 'Supplier deleted']);
    }
}
