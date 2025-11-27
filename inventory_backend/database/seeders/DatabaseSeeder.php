<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Database\Seeders\BarangSeeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Ensure at least one admin and one operator exist for testing.
        // Some environments may not have model factories available, so create users directly.
        $adminEmail = 'test@example.com';
        if (! \App\Models\User::where('email', $adminEmail)->exists()) {
            \App\Models\User::create([
                'nama' => 'Test User',
                'email' => $adminEmail,
                'password' => bcrypt('password123'),
                'role' => 'admin',
            ]);
        }

        $operatorEmail = 'operator1@example.test';
        if (! \App\Models\User::where('email', $operatorEmail)->exists()) {
            \App\Models\User::create([
                'nama' => 'Operator Satuu',
                'email' => $operatorEmail,
                'password' => bcrypt('password123'),
                'role' => 'operator',
            ]);
        }

        // Seed a sample barang for testing (if not present)
        $this->call(BarangSeeder::class);
        // Seed sample barang keluar for admin view
        $this->call(\Database\Seeders\BarangKeluarSeeder::class);
        // Seed sample stock, suppliers and categories
        $this->call(\Database\Seeders\SampleStockSeeder::class);
    }
}
