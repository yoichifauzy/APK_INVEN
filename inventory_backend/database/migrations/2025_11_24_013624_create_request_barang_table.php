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
        Schema::create('request_barang', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_user')->constrained('users')->onDelete('cascade'); // karyawan
            $table->foreignId('id_barang')->constrained('barang')->onDelete('cascade');
            $table->integer('qty');
            $table->date('tanggal_request');
            $table->enum('status', ['pending', 'approved', 'rejected', 'done'])->default('pending');
            $table->text('alasan_penolakan')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users')->onDelete('set null'); // manager
            $table->date('tanggal_approve')->nullable();
            $table->timestamps();
        });
    }


    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('request_barang');
    }
};
