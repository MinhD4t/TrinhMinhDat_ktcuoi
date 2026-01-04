using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
// 1. THÊM DÒNG NÀY ĐỂ HẾT LỖI ISACTIVE
using TrinhMinhDat_ktcuoi.Models;

namespace TrinhMinhDat_ktcuoi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    // Đảm bảo sử dụng ApplicationUser từ Models
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IConfiguration _config;
    private readonly AppDbContext _db;

    public AuthController(
        UserManager<ApplicationUser> userManager,
        IConfiguration config,
        AppDbContext db)
    {
        _userManager = userManager;
        _config = config;
        _db = db;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterDto dto)
    {
        var user = new ApplicationUser
        {
            UserName = dto.UserName,
            Email = dto.Email,
            IsActive = true // Mặc định kích hoạt khi đăng ký
        };

        var result = await _userManager.CreateAsync(user, dto.Password);
        if (!result.Succeeded)
            return BadRequest(result.Errors);

        var role = dto.Role ?? "User";
        await _userManager.AddToRoleAsync(user, role);

        return Ok("Register success");
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginDto dto)
    {
        var user = await _userManager.FindByNameAsync(dto.UserName);

        // 2. KIỂM TRA ISACTIVE TẠI ĐÂY
        if (user == null) return Unauthorized("Invalid user");

        if (!user.IsActive)
            return Unauthorized("Account is disabled. Please contact admin.");

        if (!await _userManager.CheckPasswordAsync(user, dto.Password))
            return Unauthorized("Wrong password");

        var otp = new Random().Next(100000, 999999).ToString();

        _db.TwoFactorCodes.Add(new TwoFactorCode
        {
            UserId = user.Id,
            Code = otp,
            ExpiresAt = DateTime.UtcNow.AddMinutes(5),
            Used = false
        });

        await _db.SaveChangesAsync();
        Console.WriteLine($"OTP for {user.UserName}: {otp}");

        return Ok(new { needOtp = true });
    }

    [HttpPost("verify-otp")]
    public async Task<IActionResult> VerifyOtp(VerifyOtpDto dto)
    {
        var user = await _userManager.FindByNameAsync(dto.UserName);
        if (user == null) return Unauthorized();

        var otp = await _db.TwoFactorCodes
            .Where(x =>
                x.UserId == user.Id &&
                x.Code == dto.Otp &&
                !x.Used &&
                x.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(x => x.ExpiresAt)
            .FirstOrDefaultAsync();

        if (otp == null)
            return BadRequest("OTP invalid or expired");

        otp.Used = true;
        await _db.SaveChangesAsync();

        var roles = await _userManager.GetRolesAsync(user);
        var token = GenerateToken(user.UserName!, roles.First());

        return Ok(new { token, role = roles.First() });
    }

    private string GenerateToken(string username, string role)
    {
        var jwt = _config.GetSection("Jwt");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, username),
            new Claim(ClaimTypes.Role, role)
        };

        var token = new JwtSecurityToken(
            issuer: jwt["Issuer"],
            audience: jwt["Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(double.Parse(jwt["ExpiryMinutes"]!)),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}

public class RegisterDto { public string UserName { get; set; } = ""; public string Email { get; set; } = ""; public string Password { get; set; } = ""; public string? Role { get; set; } }
public class LoginDto { public string UserName { get; set; } = ""; public string Password { get; set; } = ""; }
public class VerifyOtpDto { public string UserName { get; set; } = ""; public string Otp { get; set; } = ""; }