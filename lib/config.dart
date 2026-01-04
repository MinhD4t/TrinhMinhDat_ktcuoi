class Config {
  static const String baseUrl = "https://10.0.2.2:7082/api";

  // Endpoints cho Auth
  static const String loginUrl = "$baseUrl/Auth/login";
  static const String registerUrl = "$baseUrl/Auth/register";
  static const String verifyOtpUrl = "$baseUrl/Auth/verify-otp";

  // Endpoints cho Users - QUAY VỀ SỐ NHIỀU ĐỂ KHỚP VỚI CHUẨN BACKEND
  static const String usersUrl = "$baseUrl/Users"; 

  // Hàm tiện ích để lấy URL động theo ID String của Identity
  static String disableUserUrl(dynamic id) => "$baseUrl/Users/$id/disable";
  static String enableUserUrl(dynamic id) => "$baseUrl/Users/$id/enable";

  static String hideUserUrl(dynamic id) => "$baseUrl/Users/$id/hide";

  // Endpoints cho Calendars & Events
  static const String eventsUrl = "$baseUrl/Events"; 
  static const String calendarsUrl = "$baseUrl/Calendars"; 

  static Map<String, String> getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'accept': '*/*',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}
