<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Illuminate\Support\Facades\DB;
use App\Models\User;

class RequestBarangTest extends TestCase
{
    use RefreshDatabase;

    public function test_karyawan_can_create_request()
    {
        // create a user
        $user = User::factory()->create();

        // insert a sample item into barang table
        $idBarang = DB::table('barang')->insertGetId([
            'kode_barang' => 'TEST-001',
            'nama_barang' => 'Test Item',
            'id_kategori' => null,
            'id_supplier' => null,
            'stok' => 10,
            'lokasi' => 'Rak Test',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $payload = [
            'id_barang' => $idBarang,
            'qty' => 2,
            'tanggal_request' => now()->toDateString(),
        ];

        $res = $this->actingAs($user, 'sanctum')->postJson('/api/request-barang', $payload);
        $res->assertStatus(201);
        $this->assertDatabaseHas('request_barang', [
            'id_barang' => $idBarang,
            'id_user' => $user->id,
            'qty' => 2,
            'status' => 'pending',
        ]);
    }
}
