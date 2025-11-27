<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('barang_keluar', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_barang')->constrained('barang')->onDelete('cascade');
            $table->integer('qty');
            $table->date('tanggal_keluar');
            $table->foreignId('id_user')->constrained('users')->onDelete('cascade');
            $table->foreignId('id_request')
                ->nullable()
                ->constrained('request_barang')
                ->nullOnDelete();
            $table->text('keterangan')->nullable();
            $table->timestamps();
        });
    }



    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('barang_keluar');
    }
};
