<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class UserController extends Controller
{
    // List users (admin only)
    public function index(Request $request)
    {
        $me = $request->user();
        if (!$me || ($me->role ?? '') !== 'admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $users = User::select('id', 'nama', 'email', 'role', 'created_at')->get();
        return response()->json($users);
    }

    // Show single user
    public function show(Request $request, $id)
    {
        $me = $request->user();
        if (!$me || ($me->role ?? '') !== 'admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $user = User::find($id);
        if (!$user) return response()->json(['message' => 'Not found'], 404);
        return response()->json($user);
    }

    // Update user
    public function update(Request $request, $id)
    {
        $me = $request->user();
        if (!$me || ($me->role ?? '') !== 'admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $user = User::find($id);
        if (!$user) return response()->json(['message' => 'Not found'], 404);

        $data = $request->only(['nama', 'email', 'role', 'password']);
        $validator = Validator::make($data, [
            'email' => 'sometimes|required|email|unique:users,email,' . $id,
            'nama' => 'sometimes|required',
            'role' => 'sometimes|required',
            'password' => 'sometimes|nullable|min:6',
        ]);
        if ($validator->fails()) return response()->json(['errors' => $validator->errors()], 422);

        if (isset($data['nama'])) $user->nama = $data['nama'];
        if (isset($data['email'])) $user->email = $data['email'];
        if (isset($data['role'])) $user->role = $data['role'];
        if (!empty($data['password'])) $user->password = Hash::make($data['password']);

        $user->save();

        return response()->json(['message' => 'User updated', 'user' => $user]);
    }

    // Delete user
    public function destroy(Request $request, $id)
    {
        $me = $request->user();
        if (!$me || ($me->role ?? '') !== 'admin') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $user = User::find($id);
        if (!$user) return response()->json(['message' => 'Not found'], 404);

        $user->delete();
        return response()->json(['message' => 'User deleted']);
    }
}
