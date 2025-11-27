<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\RequestBarang;
use App\Models\User;
use App\Notifications\NewRequestCreated;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Notification;

class RequestBarangController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'id_barang' => 'required|integer|exists:barang,id',
            'qty' => 'required|numeric|min:1',
            'tanggal_request' => 'nullable|date'
        ]);

        $tanggal = $request->tanggal_request ?? now()->toDateString();

        try {
            $newRequest = RequestBarang::create([
                'id_user' => $request->user()->id,
                'id_barang' => $request->id_barang,
                'qty' => $request->qty,
                'tanggal_request' => $tanggal,
                'status' => 'pending'
            ]);

            // notify admins about new request
            try {
                $admins = User::where('role', 'admin')->get();
                if ($admins->isNotEmpty()) {
                    Notification::send($admins, new NewRequestCreated($newRequest));
                }
            } catch (\Exception $e) {
                // non-fatal: continue but log could be added
            }

            return response()->json(['message' => 'Request barang berhasil dibuat', 'data' => $newRequest], 201);
        } catch (\Illuminate\Database\QueryException $e) {
            return response()->json(['message' => 'Gagal membuat request barang: masalah pada database.', 'error' => $e->getMessage()], 500);
        }
    }

    public function index()
    {
        $rows = RequestBarang::with(['user', 'barang'])->orderBy('tanggal_request', 'desc')->get();

        $data = $rows->map(function ($r) {
            return [
                'id' => $r->id,
                'id_barang' => $r->id_barang,
                'nama_barang' => $r->barang?->nama_barang,
                'barang' => $r->barang ? [
                    'id' => $r->barang->id,
                    'nama_barang' => $r->barang->nama_barang,
                ] : null,
                'id_user' => $r->id_user,
                'user' => $r->user ? [
                    'id' => $r->user->id,
                    'nama' => $r->user->nama ?? $r->user->name ?? null,
                ] : null,
                'qty' => $r->qty,
                'status' => $r->status,
                'tanggal_request' => $r->tanggal_request,
                'alasan_penolakan' => $r->alasan_penolakan ?? null,
                'approved_by' => $r->approved_by ?? null,
                'tanggal_approve' => $r->tanggal_approve ?? null,
            ];
        })->toArray();

        return response()->json($data);
    }

    public function updateStatus(Request $request, $id)
    {
        $me = $request->user();
        if (! $me || !in_array(($me->role ?? ''), ['admin', 'manager'])) {
            return response()->json(['message' => 'Unauthorized - only admin or manager can change status'], 403);
        }

        $request->validate(['status' => 'required']);
        $requestBarang = RequestBarang::findOrFail($id);

        $newStatus = $request->status;
        $data = ['status' => $newStatus];
        if ($newStatus === 'approved') {
            $data['approved_by'] = $me->id;
            $data['tanggal_approve'] = now()->toDateString();
        }
        if ($newStatus === 'rejected') {
            $data['alasan_penolakan'] = $request->input('alasan_penolakan', null);
        }

        $requestBarang->update($data);

        return response()->json(['message' => 'Status request diperbarui', 'data' => $requestBarang]);
    }
}
