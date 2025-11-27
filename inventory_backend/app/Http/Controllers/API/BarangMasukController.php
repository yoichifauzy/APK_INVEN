<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\BarangMasuk;
use App\Models\Barang;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class BarangMasukController extends Controller
{
    // list history
    public function index(Request $request)
    {
        $me = $request->user();
        if (!$me) return response()->json(['message' => 'Unauthorized'], 403);

        $rows = BarangMasuk::with(['barang', 'supplier', 'user'])->orderByDesc('tanggal_masuk')->get();
        $data = $rows->map(function ($r) {
            return [
                'id' => $r->id,
                'id_barang' => $r->id_barang,
                'nama_barang' => $r->barang?->nama_barang,
                'id_supplier' => $r->id_supplier,
                'nama_supplier' => $r->supplier?->nama_supplier,
                'qty' => $r->qty,
                'tanggal_masuk' => $r->tanggal_masuk,
                'keterangan' => $r->keterangan,
                'id_user' => $r->id_user,
                'user_name' => $r->user?->nama ?? $r->user?->name,
                'status' => $r->status ?? 'pending',
                'approved_by' => $r->approved_by,
                'approved_at' => $r->approved_at,
                'rejected_by' => $r->rejected_by,
                'rejected_at' => $r->rejected_at,
                'reject_reason' => $r->reject_reason,
                'created_at' => $r->created_at,
            ];
        });
        return response()->json($data);
    }

    // create incoming record (operator -> pending)
    public function store(Request $request)
    {
        $me = $request->user();
        if (!$me) return response()->json(['message' => 'Unauthorized'], 403);

        $data = $request->only(['id_barang', 'id_supplier', 'qty', 'tanggal_masuk', 'keterangan']);
        $validator = Validator::make($data, [
            'id_barang' => 'required|exists:barang,id',
            'id_supplier' => 'nullable|exists:supplier,id',
            'qty' => 'required|integer|min:1',
            'tanggal_masuk' => 'required|date',
            'keterangan' => 'nullable',
        ]);
        if ($validator->fails()) return response()->json(['errors' => $validator->errors()], 422);

        $data['id_user'] = $me->id;
        $data['status'] = 'pending';

        // create record; do NOT modify stock yet
        $rec = BarangMasuk::create($data);

        return response()->json(['message' => 'Barang masuk created (pending)', 'item' => $rec], 201);
    }

    // approve pending masuk (admin) -> increase stok
    public function approve(Request $request, $id)
    {
        $me = $request->user();
        if (!$me || ($me->role ?? '') !== 'admin') return response()->json(['message' => 'Unauthorized'], 403);

        $rec = BarangMasuk::find($id);
        if (!$rec) return response()->json(['message' => 'Not found'], 404);
        if (($rec->status ?? 'pending') !== 'pending') return response()->json(['message' => 'Only pending records can be approved'], 422);

        DB::beginTransaction();
        try {
            // increase stock
            $barang = Barang::find($rec->id_barang);
            if ($barang) {
                $barang->stok = ($barang->stok ?? 0) + (int)$rec->qty;
                $barang->save();
            }

            $rec->status = 'approved';
            $rec->approved_by = $me->id;
            $rec->approved_at = Carbon::now();
            $rec->save();

            // log activity for manager/reporting
            DB::table('log_aktivitas')->insert([
                'id_user' => $me->id,
                'aktivitas' => "Approved barang_masuk id={$rec->id} by user={$me->id}",
                'waktu' => Carbon::now(),
            ]);

            DB::commit();
            return response()->json(['message' => 'Approved', 'item' => $rec]);
        } catch (\Exception $ex) {
            DB::rollBack();
            return response()->json(['message' => 'Error', 'error' => $ex->getMessage()], 500);
        }
    }

    // reject pending masuk (admin) -> do not change stock
    public function reject(Request $request, $id)
    {
        $me = $request->user();
        if (!$me || ($me->role ?? '') !== 'admin') return response()->json(['message' => 'Unauthorized'], 403);

        $rec = BarangMasuk::find($id);
        if (!$rec) return response()->json(['message' => 'Not found'], 404);
        if (($rec->status ?? 'pending') !== 'pending') return response()->json(['message' => 'Only pending records can be rejected'], 422);

        $reason = $request->input('reason');
        $rec->status = 'rejected';
        $rec->rejected_by = $me->id;
        $rec->rejected_at = Carbon::now();
        $rec->reject_reason = $reason;
        $rec->save();

        DB::table('log_aktivitas')->insert([
            'id_user' => $me->id,
            'aktivitas' => "Rejected barang_masuk id={$rec->id} by user={$me->id} reason=" . ($reason ?? '-'),
            'waktu' => Carbon::now(),
        ]);

        return response()->json(['message' => 'Rejected', 'item' => $rec]);
    }

    // optional delete (admin)
    public function destroy(Request $request, $id)
    {
        $me = $request->user();
        if (!$me || ($me->role ?? '') !== 'admin') return response()->json(['message' => 'Unauthorized'], 403);
        $rec = BarangMasuk::find($id);
        if (!$rec) return response()->json(['message' => 'Not found'], 404);

        // If record already approved, reverse stock
        if (($rec->status ?? '') === 'approved') {
            $barang = Barang::find($rec->id_barang);
            if ($barang) {
                $barang->stok = max(0, ($barang->stok ?? 0) - (int)$rec->qty);
                $barang->save();
            }
        }

        $rec->delete();
        return response()->json(['message' => 'Deleted']);
    }

    // update record (allow edit while pending)
    public function update(Request $request, $id)
    {
        $me = $request->user();
        if (!$me || ($me->role ?? '') !== 'admin') return response()->json(['message' => 'Unauthorized'], 403);

        $rec = BarangMasuk::find($id);
        if (!$rec) return response()->json(['message' => 'Not found'], 404);
        if (($rec->status ?? 'pending') !== 'pending') return response()->json(['message' => 'Only pending records can be edited'], 422);

        $data = $request->only(['id_barang', 'id_supplier', 'qty', 'tanggal_masuk', 'keterangan']);
        $validator = Validator::make($data, [
            'id_barang' => 'sometimes|required|exists:barang,id',
            'id_supplier' => 'nullable|exists:supplier,id',
            'qty' => 'sometimes|required|integer|min:1',
            'tanggal_masuk' => 'sometimes|required|date',
            'keterangan' => 'nullable',
        ]);
        if ($validator->fails()) return response()->json(['errors' => $validator->errors()], 422);

        $rec->fill($data);
        $rec->save();
        return response()->json(['message' => 'Updated', 'item' => $rec]);
    }
}
