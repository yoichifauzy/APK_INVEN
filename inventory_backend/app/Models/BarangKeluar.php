<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BarangKeluar extends Model
{
    protected $table = 'barang_keluar';
    // Migration defines columns: id_barang, qty, tanggal_keluar, id_user, id_request, keterangan
    protected $fillable = [
        'id_request',
        'id_user',
        'id_barang',
        'qty',
        'tanggal_keluar',
        'keterangan',
        'lokasi',
        'status',
    ];

    // Standardize attribute names for API consumers
    protected $appends = ['jumlah_keluar', 'id_operator'];

    public function request()
    {
        return $this->belongsTo(RequestBarang::class, 'id_request');
    }

    public function operator()
    {
        return $this->belongsTo(User::class, 'id_user');
    }

    public function barang()
    {
        return $this->belongsTo(Barang::class, 'id_barang');
    }

    // Accessor to present qty as jumlah_keluar for frontend compatibility
    public function getJumlahKeluarAttribute()
    {
        return $this->attributes['qty'] ?? null;
    }

    // Accessor to present id_user as id_operator
    public function getIdOperatorAttribute()
    {
        return $this->attributes['id_user'] ?? null;
    }
}
