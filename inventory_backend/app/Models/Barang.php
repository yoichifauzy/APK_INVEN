<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Barang extends Model
{
    protected $table = 'barang';

    protected $fillable = [
        'kode_barang',
        'nama_barang',
        'id_kategori',
        'id_supplier',
        'stok',
        'satuan',
        'lokasi',
        'harga',
    ];

    public function supplier()
    {
        return $this->belongsTo(Supplier::class, 'id_supplier');
    }

    public function kategori()
    {
        return $this->belongsTo(\App\Models\Kategori::class, 'id_kategori');
    }
}
