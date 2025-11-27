<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\BarangKeluar;
use App\Models\Barang;
use App\Models\User;

class BarangKeluarSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        if (BarangKeluar::count() > 0) return;

        $barangId = Barang::value('id');
        $userId = User::value('id');

        if (! $barangId || ! $userId) return;

        $samples = [
            [
                'id_barang' => $barangId,
                'qty' => 2,
                'tanggal_keluar' => now()->subDays(3)->toDateString(),
                'id_user' => $userId,
                'id_request' => null,
                'keterangan' => 'Keperluan: Departemen IT - Instalasi perangkat',
                'status' => 'approved',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'id_barang' => $barangId,
                'qty' => 5,
                'tanggal_keluar' => now()->subDays(2)->toDateString(),
                'id_user' => $userId,
                'id_request' => null,
                'keterangan' => 'Keperluan: Departemen Operasional - Konsumsi',
                'status' => 'pending',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'id_barang' => $barangId,
                'qty' => 1,
                'tanggal_keluar' => now()->toDateString(),
                'id_user' => $userId,
                'id_request' => null,
                'keterangan' => 'Keperluan: Sample penggunaan demo',
                'status' => 'rejected',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        DB::table('barang_keluar')->insert($samples);
    }
}
