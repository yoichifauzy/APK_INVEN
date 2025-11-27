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
            if (!Schema::hasColumn('barang', 'id_supplier')) {
                $table->foreignId('id_supplier')->nullable()->constrained('supplier')->nullOnDelete()->after('nama_barang');
            }
            if (!Schema::hasColumn('barang', 'harga')) {
                $table->decimal('harga', 15, 2)->default(0)->after('satuan');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('barang', function (Blueprint $table) {
            if (Schema::hasColumn('barang', 'id_supplier')) {
                $table->dropForeign(['id_supplier']);
                $table->dropColumn('id_supplier');
            }
            if (Schema::hasColumn('barang', 'harga')) {
                $table->dropColumn('harga');
            }
        });
    }
};
