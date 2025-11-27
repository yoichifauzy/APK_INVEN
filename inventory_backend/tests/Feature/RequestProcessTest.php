<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Illuminate\Support\Facades\DB;
use App\Models\User;

class RequestProcessTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_approve_request_and_operator_can_process()
    {
        // create admin, operator and requester
        $admin = User::factory()->create(['role' => 'admin']);
        $operator = User::factory()->create(['role' => 'operator']);
        $requester = User::factory()->create(['role' => 'karyawan']);

        // insert a sample item
        $idBarang = DB::table('barang')->insertGetId([
            'kode_barang' => 'TEST-002',
            'nama_barang' => 'Process Item',
            'id_kategori' => null,
            'id_supplier' => null,
            'stok' => 5,
            'lokasi' => 'Rak P',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // create request (pending)
        $payload = [
            'id_barang' => $idBarang,
            'qty' => 3,
            'tanggal_request' => now()->toDateString(),
        ];

        $res = $this->actingAs($requester, 'sanctum')->postJson('/api/request-barang', $payload);
        $res->assertStatus(201);
        $reqId = $res->json('data.id');

        // admin approves
        $res2 = $this->actingAs($admin, 'sanctum')->putJson("/api/request-barang/{$reqId}/status", ['status' => 'approved']);
        $res2->assertStatus(200);
        $this->assertDatabaseHas('request_barang', ['id' => $reqId, 'status' => 'approved', 'approved_by' => $admin->id]);

        // operator processes the request
        $res3 = $this->actingAs($operator, 'sanctum')->postJson("/api/barang-keluar/process-request/{$reqId}", ['qty' => 3, 'lokasi' => 'Rak P']);
        $res3->assertStatus(201);

        // assert barang_keluar and stock decreased and request status done
        $this->assertDatabaseHas('barang_keluar', ['id_request' => $reqId, 'qty' => 3]);
        $this->assertDatabaseHas('request_barang', ['id' => $reqId, 'status' => 'done']);
        $this->assertDatabaseHas('barang', ['id' => $idBarang, 'stok' => 2]);
    }
}
