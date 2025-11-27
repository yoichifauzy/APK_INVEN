<?php

namespace Database\Seeders;

use App\Models\Barang;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class BarangSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        if (Barang::count() === 0) {
            $kategoriId = DB::table('kategori')->value('id');
            if (! $kategoriId) {
                $kategoriId = DB::table('kategori')->insertGetId([
                    'nama_kategori' => 'Umum',
                    'deskripsi' => 'Kategori bawaan untuk seed',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            Barang::create([
                'kode_barang' => 'BRG-001',
                'nama_barang' => 'Sample Barang',
                'id_kategori' => $kategoriId,
                'satuan' => 'pcs',
                'stok' => 100,
                'stok_minimum' => 0,
                'lokasi' => 'Gudang',
            ]);
        }
    }
}
