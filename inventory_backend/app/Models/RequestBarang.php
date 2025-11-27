<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RequestBarang extends Model
{
    protected $table = 'request_barang';

    protected $fillable = [
        'id_user',
        'id_barang',
        'qty',
        'tanggal_request',
        'status', // pending, approved, rejected, done
        'alasan_penolakan',
        'approved_by',
        'tanggal_approve'
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'id_user');
    }

    public function barang()
    {
        return $this->belongsTo(Barang::class, 'id_barang');
    }
}
