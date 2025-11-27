<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BarangMasuk extends Model
{
    protected $table = 'barang_masuk';

    protected $fillable = [
        'id_barang',
        'id_supplier',
        'qty',
        'tanggal_masuk',
        'keterangan',
        'id_user',
        'status',
        'approved_by',
        'approved_at',
        'rejected_by',
        'rejected_at',
        'reject_reason',
    ];

    public function barang()
    {
        return $this->belongsTo(Barang::class, 'id_barang');
    }

    public function supplier()
    {
        return $this->belongsTo(Supplier::class, 'id_supplier');
    }

    public function user()
    {
        return $this->belongsTo(\App\Models\User::class, 'id_user');
    }

    // alias for `user` to keep relation name consistent with other models
    public function operator()
    {
        return $this->belongsTo(\App\Models\User::class, 'id_user');
    }
}
