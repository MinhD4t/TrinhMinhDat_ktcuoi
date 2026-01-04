using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
// Đảm bảo namespace này khớp với thư mục chứa ApplicationUser.cs của bạn
using TrinhMinhDat_ktcuoi.Models;

namespace TrinhMinhDat_ktcuoi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Yêu cầu người dùng phải đăng nhập để truy cập
public class UsersController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly RoleManager<IdentityRole> _roleManager;

    public UsersController(
        UserManager<ApplicationUser> userManager,
        RoleManager<IdentityRole> roleManager)
    {
        _userManager = userManager;
        _roleManager = roleManager;
    }

    // ==========================================
    // 1. LẤY DANH SÁCH NGƯỜI DÙNG (Cho cả User và Admin)
    // ==========================================
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        // Trả về thông tin bao gồm cột IsActive bạn đã thêm
        var users = await _userManager.Users
            .Select(u => new
            {
                u.Id,
                u.UserName,
                u.Email,
                u.IsActive, // Thuộc tính quan trọng cho Flutter
                IsLocked = u.LockoutEnd != null && u.LockoutEnd > DateTimeOffset.UtcNow,
                u.TwoFactorEnabled
            })
            .ToListAsync();

        return Ok(users);
    }

    // ==========================================
    // 2. LẤY CHI TIẾT THEO ID
    // ==========================================
    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(string id)
    {
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return NotFound("User not found");

        var roles = await _userManager.GetRolesAsync(user);

        return Ok(new
        {
            user.Id,
            user.UserName,
            user.Email,
            Roles = roles,
            user.IsActive,
            IsLocked = user.LockoutEnd != null && user.LockoutEnd > DateTimeOffset.UtcNow,
            user.TwoFactorEnabled
        });
    }

    // ==========================================
    // 3. CÁC CHỨC NĂNG QUẢN TRỊ (Chỉ Admin mới có quyền)
    // ==========================================

    [HttpPost("change-role")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ChangeRole([FromBody] ChangeRoleDto dto)
    {
        var user = await _userManager.FindByIdAsync(dto.UserId);
        if (user == null) return NotFound("User not found");

        if (!await _roleManager.RoleExistsAsync(dto.Role))
            return BadRequest("Role does not exist");

        var currentRoles = await _userManager.GetRolesAsync(user);
        await _userManager.RemoveFromRolesAsync(user, currentRoles);
        await _userManager.AddToRoleAsync(user, dto.Role);

        return Ok("Role changed successfully");
    }

    [HttpPut("{id}/disable")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DisableUser(string id)
    {
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return NotFound("User not found");

        user.IsActive = false; // Vô hiệu hóa tài khoản
        var result = await _userManager.UpdateAsync(user);

        return result.Succeeded ? Ok("User disabled") : BadRequest(result.Errors);
    }

    [HttpPut("{id}/enable")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> EnableUser(string id)
    {
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return NotFound("User not found");

        user.IsActive = true; // Kích hoạt lại tài khoản
        var result = await _userManager.UpdateAsync(user);

        return result.Succeeded ? Ok("User enabled") : BadRequest(result.Errors);
    }

    [HttpPut("{id}/lock")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> LockUser(string id)
    {
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return NotFound("User not found");

        user.LockoutEnd = DateTimeOffset.UtcNow.AddYears(100);
        await _userManager.UpdateAsync(user);

        return Ok("User locked");
    }

    [HttpPut("{id}/unlock")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UnlockUser(string id)
    {
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return NotFound("User not found");

        user.LockoutEnd = null;
        await _userManager.UpdateAsync(user);

        return Ok("User unlocked");
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(string id)
    {
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return NotFound("User not found");

        await _userManager.DeleteAsync(user);
        return Ok("User deleted");
    }
}

public class ChangeRoleDto
{
    public string UserId { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
}