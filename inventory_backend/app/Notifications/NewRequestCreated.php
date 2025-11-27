<?php

namespace App\Notifications;

use App\Models\RequestBarang;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Notifications\Messages\MailMessage;

class NewRequestCreated extends Notification
{
    use Queueable;

    protected $requestBarang;

    public function __construct(RequestBarang $requestBarang)
    {
        $this->requestBarang = $requestBarang;
    }

    public function via($notifiable)
    {
        return ['mail', 'database'];
    }

    public function toMail($notifiable)
    {
        $rb = $this->requestBarang;
        $barangName = $rb->barang?->nama_barang ?? 'N/A';
        $requester = $rb->user?->nama ?? ($rb->user?->name ?? 'Peminta');

        return (new MailMessage)
            ->subject('New Request Barang: ' . $barangName)
            ->line("Peminta: {$requester}")
            ->line("Barang: {$barangName}")
            ->line("Jumlah: {$rb->qty}")
            ->action('Lihat Request', url('/admin/requests'))
            ->line('Silakan tinjau dan setujui request ini.');
    }

    public function toArray($notifiable)
    {
        $rb = $this->requestBarang;
        return [
            'request_id' => $rb->id,
            'id_barang' => $rb->id_barang,
            'qty' => $rb->qty,
            'id_user' => $rb->id_user,
        ];
    }
}
