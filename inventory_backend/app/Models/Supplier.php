<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Supplier extends Model
{
    protected $table = 'supplier';

    protected $fillable = [
        'nama_supplier',
        'kontak',
        'alamat'
    ];

    public function barang()
    {
        return $this->hasMany(Barang::class, 'id_supplier');
    }
}
