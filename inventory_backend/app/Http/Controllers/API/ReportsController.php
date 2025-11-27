<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Barang;
use App\Models\RequestBarang;
use App\Models\BarangMasuk;
use App\Models\BarangKeluar;

class ReportsController extends Controller
{
    // GET /api/reports?type=stock|request|masuk|keluar&format=json|csv|html&from=&to=&category=&supplier=
    public function index(Request $request)
    {
        $type = $request->query('type', 'stock');
        $format = $request->query('format', 'json');

        // filters
        $from = $request->query('from');
        $to = $request->query('to');
        $category = $request->query('category');
        $supplier = $request->query('supplier');

        if ($type === 'stock') {
            $query = Barang::query()->leftJoin('kategori', 'barang.id_kategori', '=', 'kategori.id')
                ->leftJoin('supplier', 'barang.id_supplier', '=', 'supplier.id')
                ->select([
                    'barang.kode_barang',
                    'barang.nama_barang',
                    'kategori.nama_kategori as kategori',
                    'barang.stok',
                    'barang.lokasi',
                    'supplier.nama_supplier as supplier',
                ]);

            if ($category) $query->where('barang.id_kategori', $category);
            if ($supplier) $query->where('barang.id_supplier', $supplier);

            $rows = $query->get()->map(function ($r) {
                if ($r instanceof \Illuminate\Database\Eloquent\Model) {
                    return $r->toArray();
                }
                return (array) $r;
            })->toArray();

            return $this->output($rows, $format, 'laporan_stok');
        }

        if ($type === 'request') {
            $query = RequestBarang::with(['user', 'barang'])->orderBy('tanggal_request', 'desc');
            if ($from) $query->whereDate('tanggal_request', '>=', $from);
            if ($to) $query->whereDate('tanggal_request', '<=', $to);
            if ($category) $query->where('id_barang', function ($q) use ($category) {
                // filter by barang category
                $q->select('id')->from('barang')->where('id_kategori', $category);
            });
            $rows = $query->get()->map(function ($r) {
                return [
                    'tanggal' => $r->tanggal_request,
                    'karyawan' => $r->user?->name,
                    'barang' => $r->barang?->nama_barang,
                    'qty' => $r->qty,
                    'status' => $r->status,
                ];
            })->toArray();

            return $this->output($rows, $format, 'laporan_request');
        }

        if ($type === 'masuk') {
            $query = BarangMasuk::with(['barang', 'supplier', 'operator'])->orderBy('tanggal_masuk', 'desc');
            if ($from) $query->whereDate('tanggal_masuk', '>=', $from);
            if ($to) $query->whereDate('tanggal_masuk', '<=', $to);
            if ($category) $query->whereHas('barang', function ($q) use ($category) {
                $q->where('id_kategori', $category);
            });
            if ($supplier) $query->where('id_supplier', $supplier);

            $rows = $query->get()->map(function ($r) {
                return [
                    'tanggal_masuk' => $r->tanggal_masuk,
                    'barang' => $r->barang?->nama_barang,
                    'supplier' => $r->supplier?->nama_supplier,
                    'qty' => $r->qty,
                    'operator' => $r->operator?->name,
                    'keterangan' => $r->keterangan,
                ];
            })->toArray();

            return $this->output($rows, $format, 'laporan_masuk');
        }

        // keluar
        $query = BarangKeluar::with(['barang', 'request', 'operator'])->orderBy('tanggal_keluar', 'desc');
        if ($from) $query->whereDate('tanggal_keluar', '>=', $from);
        if ($to) $query->whereDate('tanggal_keluar', '<=', $to);
        if ($category) $query->whereHas('barang', function ($q) use ($category) {
            $q->where('id_kategori', $category);
        });
        if ($supplier) $query->whereHas('barang', function ($q) use ($supplier) {
            $q->where('id_supplier', $supplier);
        });

        $rows = $query->get()->map(function ($r) {
            return [
                'tanggal_keluar' => $r->tanggal_keluar,
                'barang' => $r->barang?->nama_barang,
                'request_from' => $r->request?->user?->name ?? '-',
                'qty' => $r->qty,
                'operator' => $r->operator?->name,
                'keterangan' => $r->keterangan,
            ];
        })->toArray();

        return $this->output($rows, $format, 'laporan_keluar');
    }

    /**
     * Debug method - return stock rows without requiring auth.
     * Only for development/testing.
     */
    public function debugStock(Request $request)
    {
        $rows = Barang::leftJoin('kategori', 'barang.id_kategori', '=', 'kategori.id')
            ->leftJoin('supplier', 'barang.id_supplier', '=', 'supplier.id')
            ->select([
                'barang.kode_barang',
                'barang.nama_barang',
                'kategori.nama_kategori as kategori',
                'barang.stok',
                'barang.lokasi',
                'supplier.nama_supplier as supplier',
            ])->get();

        $data = $rows->map(function ($r) {
            if ($r instanceof \Illuminate\Database\Eloquent\Model) {
                return $r->toArray();
            }
            return (array) $r;
        })->toArray();

        return response()->json($data);
    }

    protected function output(array $rows, string $format, string $basename)
    {
        if ($format === 'json') {
            return response()->json($rows);
        }

        if ($format === 'csv' || $format === 'excel') {
            $filename = $basename . '.csv';
            $callback = function () use ($rows) {
                $out = fopen('php://output', 'w');
                if (count($rows) === 0) {
                    fclose($out);
                    return;
                }
                // header
                fputcsv($out, array_keys($rows[0]));
                foreach ($rows as $row) {
                    fputcsv($out, array_values($row));
                }
                fclose($out);
            };
            return response()->streamDownload($callback, $filename, ["Content-Type" => "text/csv"]);
        }

        // html (printable) - simple table
        $html = '<!doctype html><html><head><meta charset="utf-8"><title>' . htmlspecialchars($basename) . '</title></head><body>';
        $html .= '<h2>' . htmlspecialchars($basename) . '</h2>';
        if (count($rows) === 0) {
            $html .= '<p>No data</p>';
        } else {
            $html .= '<table border="1" cellpadding="6" cellspacing="0">';
            $html .= '<thead><tr>';
            foreach (array_keys($rows[0]) as $h) $html .= '<th>' . htmlspecialchars($h) . '</th>';
            $html .= '</tr></thead><tbody>';
            foreach ($rows as $r) {
                $html .= '<tr>';
                foreach ($r as $c) $html .= '<td>' . htmlspecialchars((string) $c) . '</td>';
                $html .= '</tr>';
            }
            $html .= '</tbody></table>';
        }
        $html .= '</body></html>';

        $filename = $basename . '.html';
        $callback = function () use ($html) {
            echo $html;
        };
        return response()->streamDownload($callback, $filename, ["Content-Type" => "text/html"]);
    }
}
