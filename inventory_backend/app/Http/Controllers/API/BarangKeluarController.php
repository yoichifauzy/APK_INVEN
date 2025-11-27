<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\BarangKeluar;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB as FacadeDB;

class BarangKeluarController extends Controller
{
    public function store(Request $request)
    {
        $me = $request->user();
        if (! $me || ($me->role ?? '') !== 'operator') {
            return response()->json(['message' => 'Unauthorized - only operator can create barang keluar'], 403);
        }
        $request->validate([
            'id_barang' => 'required',
            'qty' => 'required|numeric|min:1',
        ]);

        $record = BarangKeluar::create([
            'id_request' => $request->id_request ?? null,
            'id_barang' => $request->id_barang,
            'qty' => $request->qty,
            'id_user' => $request->user()->id,
            'tanggal_keluar' => $request->tanggal_keluar ?? now()->toDateString(),
            'keterangan' => $request->keterangan ?? null,
            'status' => $request->status ?? 'pending',
        ]);

        return response()->json(['message' => 'Barang keluar dicatat', 'data' => $record], 201);
    }

    public function index()
    {
        $rows = BarangKeluar::with(['operator', 'barang', 'request'])->get();
        // map to friendlier structure for frontend
        return $rows->map(function ($r) {
            return [
                'id' => $r->id,
                'id_barang' => $r->id_barang,
                'nama_barang' => $r->barang?->nama_barang,
                'qty' => $r->qty,
                'jumlah_keluar' => $r->qty,
                'status' => $r->status ?? 'pending',
                'tanggal_keluar' => $r->tanggal_keluar,
                'id_user' => $r->id_user,
                'user_name' => $r->operator?->nama ?? $r->operator?->name,
                'id_request' => $r->id_request,
                'keterangan' => $r->keterangan,
                'created_at' => $r->created_at,
                'updated_at' => $r->updated_at,
            ];
        })->values();
    }

    public function update(Request $request, $id)
    {
        $record = BarangKeluar::find($id);
        if (! $record) return response()->json(['message' => 'Not found'], 404);

        $request->validate([
            'qty' => 'required|numeric|min:1',
            'status' => 'nullable|in:pending,approved,rejected,done',
        ]);

        $record->qty = $request->qty;
        if ($request->has('keterangan')) $record->keterangan = $request->keterangan;
        if ($request->has('tanggal_keluar')) $record->tanggal_keluar = $request->tanggal_keluar;
        if ($request->has('status')) $record->status = $request->status;
        $record->save();

        return response()->json(['message' => 'Updated', 'data' => $record]);
    }

    public function destroy($id)
    {
        $record = BarangKeluar::find($id);
        if (! $record) return response()->json(['message' => 'Not found'], 404);
        $record->delete();
        return response()->json(['message' => 'Deleted']);
    }

    /**
     * Process an approved RequestBarang into an actual barang_keluar entry.
     * POST /api/barang-keluar/process-request/{requestId}
     * body: { qty, lokasi, keterangan }
     */
    public function processRequest(Request $request, $requestId)
    {
        $me = $request->user();
        if (! $me || ($me->role ?? '') !== 'operator') {
            return response()->json(['message' => 'Unauthorized - only operator can process requests'], 403);
        }

        // find request
        $req = \App\Models\RequestBarang::find($requestId);
        if (! $req) return response()->json(['message' => 'Request not found'], 404);
        if (($req->status ?? '') !== 'approved') {
            return response()->json(['message' => 'Request must be approved before processing'], 422);
        }

        $request->validate([
            'qty' => 'required|numeric|min:1',
            'lokasi' => 'nullable|string',
            'keterangan' => 'nullable|string',
        ]);

        $qty = $request->qty;

        // check stock
        $barang = \App\Models\Barang::find($req->id_barang);
        if (! $barang) return response()->json(['message' => 'Barang not found'], 404);
        if (($barang->stok ?? 0) < $qty) {
            return response()->json(['message' => 'Insufficient stock'], 422);
        }

        // process atomically
        FacadeDB::beginTransaction();
        try {
            // create barang_keluar
            $bk = BarangKeluar::create([
                'id_request' => $req->id,
                'id_barang' => $req->id_barang,
                'qty' => $qty,
                'id_user' => $me->id,
                'tanggal_keluar' => now()->toDateString(),
                'keterangan' => $request->keterangan ?? null,
                'lokasi' => $request->lokasi ?? null,
                'status' => 'done',
            ]);

            // reduce stock
            $barang->stok = $barang->stok - $qty;
            $barang->save();

            // mark request done
            $req->status = 'done';
            $req->save();

            FacadeDB::commit();
            return response()->json(['message' => 'Processed', 'data' => $bk], 201);
        } catch (\Exception $e) {
            FacadeDB::rollBack();
            return response()->json(['message' => 'Failed to process', 'error' => $e->getMessage()], 500);
        }
    }
}
