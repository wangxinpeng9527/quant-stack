<?php
namespace app\controller;

use Carbon\Carbon;
use support\Db;
use support\Redis;
use Webman\Http\Request;

class PushController
{
    public function push(Request $request)
    {
        $data = $request->post();

        $id = Db::table('signals')->insertGetId([
            'symbol'     => $data['symbol'],
            'timeframe'  => $data['timeframe'] ?? '1m',
            'side'       => $data['side'],
            'confidence' => $data['confidence'] ?? null,
            'signal_at'  => $data['signal_at'],
            'payload'    => json_encode($data, JSON_UNESCAPED_UNICODE),
            'created_at' => Carbon::now()->toDateTimeString(),
            'updated_at' => Carbon::now()->toDateTimeString(),
        ]);

        $stream = 'signal.created';

        Redis::xAdd($stream, '*', [
            'signal_id' => (string)$id,
            'symbol'    => (string)($data['symbol'] ?? ''),
            'side'      => (string)($data['side'] ?? ''),
        ]);

        return json(['ok' => true, 'id' => $id, 'stream' => $stream])
            ->withHeader('X-Stream', $stream)
            ->withHeader('X-Source', 'webman');
    }
}
