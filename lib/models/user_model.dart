class UserModel {
  final String token;
  final String username;
  final String email;
  final String rol;
  final int userId;
  final int? residenteId;

  UserModel({
    required this.token,
    required this.username,
    required this.email,
    required this.rol,
    required this.userId,
    this.residenteId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      token: json['token'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? '',
      userId: json['user_id'] ?? json['id'] ?? 0,
      residenteId: json['residente_id'] ?? json['residente'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'username': username,
      'email': email,
      'rol': rol,
      'user_id': userId,
      'residente_id': residenteId,
    };
  }

  bool get isResidente => rol.toLowerCase() == 'residente';
  bool get isEmpleado => rol.toLowerCase() == 'empleado';
  bool get isSeguridad => rol.toLowerCase() == 'seguridad';
  bool get isAdmin => rol.toLowerCase() == 'administrador';
  
  // Verificar si puede acceder desde la app móvil
  bool get canAccessMobile => isResidente || isEmpleado || isSeguridad;
}

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class LoginResponse {
  final bool success;
  final String? message;
  final UserModel? user;

  LoginResponse({
    required this.success,
    this.message,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}
