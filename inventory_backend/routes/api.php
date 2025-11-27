<?php

use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\RequestBarangController;
use App\Http\Controllers\API\BarangKeluarController;
use App\Http\Controllers\API\TrackingController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Debug route (no auth) to quickly return stock rows for testing/reporting
Route::get('/debug/reports/stock', [\App\Http\Controllers\API\ReportsController::class, 'debugStock']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    // return current authenticated user (used by frontend)
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    Route::post('/request-barang', [RequestBarangController::class, 'store']);
    Route::get('/request-barang', [RequestBarangController::class, 'index']);
    Route::put('/request-barang/{id}/status', [RequestBarangController::class, 'updateStatus']);

    Route::post('/barang-keluar', [BarangKeluarController::class, 'store']);
    Route::get('/barang-keluar', [BarangKeluarController::class, 'index']);
    Route::put('/barang-keluar/{id}', [BarangKeluarController::class, 'update']);
    Route::delete('/barang-keluar/{id}', [BarangKeluarController::class, 'destroy']);
    Route::post('/barang-keluar/process-request/{id}', [BarangKeluarController::class, 'processRequest']);

    Route::get('/tracking', [TrackingController::class, 'tracking']);

    // User management (admin)
    Route::get('/users', [\App\Http\Controllers\API\UserController::class, 'index']);
    Route::get('/users/{id}', [\App\Http\Controllers\API\UserController::class, 'show']);
    Route::put('/users/{id}', [\App\Http\Controllers\API\UserController::class, 'update']);
    Route::delete('/users/{id}', [\App\Http\Controllers\API\UserController::class, 'destroy']);

    // Supplier management
    Route::get('/suppliers', [\App\Http\Controllers\API\SupplierController::class, 'index']);
    Route::get('/suppliers/{id}', [\App\Http\Controllers\API\SupplierController::class, 'show']);
    Route::post('/suppliers', [\App\Http\Controllers\API\SupplierController::class, 'store']);
    Route::put('/suppliers/{id}', [\App\Http\Controllers\API\SupplierController::class, 'update']);
    Route::delete('/suppliers/{id}', [\App\Http\Controllers\API\SupplierController::class, 'destroy']);

    // Category management
    Route::get('/categories', [\App\Http\Controllers\API\KategoriController::class, 'index']);

    // Barang (items) management
    Route::get('/items', [\App\Http\Controllers\API\BarangController::class, 'index']);
    Route::get('/items/{id}', [\App\Http\Controllers\API\BarangController::class, 'show']);
    Route::post('/items', [\App\Http\Controllers\API\BarangController::class, 'store']);
    Route::put('/items/{id}', [\App\Http\Controllers\API\BarangController::class, 'update']);
    Route::delete('/items/{id}', [\App\Http\Controllers\API\BarangController::class, 'destroy']);

    // Barang Masuk (incoming items)
    Route::get('/barang-masuk', [\App\Http\Controllers\API\BarangMasukController::class, 'index']);
    Route::post('/barang-masuk', [\App\Http\Controllers\API\BarangMasukController::class, 'store']);
    Route::put('/barang-masuk/{id}', [\App\Http\Controllers\API\BarangMasukController::class, 'update']);
    Route::delete('/barang-masuk/{id}', [\App\Http\Controllers\API\BarangMasukController::class, 'destroy']);
    Route::patch('/barang-masuk/{id}/approve', [\App\Http\Controllers\API\BarangMasukController::class, 'approve']);
    Route::patch('/barang-masuk/{id}/reject', [\App\Http\Controllers\API\BarangMasukController::class, 'reject']);

    // Reports
    Route::get('/reports', [\App\Http\Controllers\API\ReportsController::class, 'index']);
});
