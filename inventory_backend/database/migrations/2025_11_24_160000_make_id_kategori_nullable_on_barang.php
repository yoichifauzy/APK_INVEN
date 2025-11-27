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
        Schema::table('barang', function (Blueprint $table) {
            // make id_kategori nullable and adjust foreign key to set null on delete
            $table->dropForeign(['id_kategori']);
            $table->unsignedBigInteger('id_kategori')->nullable()->change();
            $table->foreign('id_kategori')->references('id')->on('kategori')->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('barang', function (Blueprint $table) {
            $table->dropForeign(['id_kategori']);
            $table->unsignedBigInteger('id_kategori')->nullable(false)->change();
            $table->foreign('id_kategori')->references('id')->on('kategori')->onDelete('cascade');
        });
    }
};
