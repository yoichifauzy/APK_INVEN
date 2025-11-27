<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\Barang;

class SampleStockSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        // create some suppliers if not exist
        $supplierA = DB::table('supplier')->where('nama_supplier', 'Supplier A')->value('id');
        if (! $supplierA) {
            $supplierA = DB::table('supplier')->insertGetId([
                'nama_supplier' => 'Supplier A',
                'kontak' => 'supplierA@example.test',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
        $supplierB = DB::table('supplier')->where('nama_supplier', 'Supplier B')->value('id');
        if (! $supplierB) {
            $supplierB = DB::table('supplier')->insertGetId([
                'nama_supplier' => 'Supplier B',
                'kontak' => 'supplierB@example.test',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // ensure a kategori exists
        $kategoriId = DB::table('kategori')->where('nama_kategori', 'Elektronik')->value('id');
        if (! $kategoriId) {
            $kategoriId = DB::table('kategori')->insertGetId([
                'nama_kategori' => 'Elektronik',
                'deskripsi' => 'Perangkat elektronik dan aksesori',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        $kategori2 = DB::table('kategori')->where('nama_kategori', 'Konsumabel')->value('id');
        if (! $kategori2) {
            $kategori2 = DB::table('kategori')->insertGetId([
                'nama_kategori' => 'Konsumabel',
                'deskripsi' => 'Barang habis pakai',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // sample items
        $samples = [
            [
                'kode_barang' => 'BRG-1001',
                'nama_barang' => 'Mouse Wireless',
                'id_kategori' => $kategoriId,
                'satuan' => 'pcs',
                'stok' => 50,
                'stok_minimum' => 5,
                'lokasi' => 'Rak A1',
                'id_supplier' => $supplierA,
                'harga' => 120000,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'kode_barang' => 'BRG-1002',
                'nama_barang' => 'Keyboard Mechanical',
                'id_kategori' => $kategoriId,
                'satuan' => 'pcs',
                'stok' => 20,
                'stok_minimum' => 3,
                'lokasi' => 'Rak A2',
                'id_supplier' => $supplierA,
                'harga' => 450000,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'kode_barang' => 'BRG-2001',
                'nama_barang' => 'Paper A4 (500 lembar)',
                'id_kategori' => $kategori2,
                'satuan' => 'pack',
                'stok' => 100,
                'stok_minimum' => 10,
                'lokasi' => 'Rak B1',
                'id_supplier' => $supplierB,
                'harga' => 75000,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        foreach ($samples as $s) {
            // insert only if kode_barang not exists
            $exists = DB::table('barang')->where('kode_barang', $s['kode_barang'])->exists();
            if (! $exists) {
                DB::table('barang')->insert($s);
            }
        }
    }
}
