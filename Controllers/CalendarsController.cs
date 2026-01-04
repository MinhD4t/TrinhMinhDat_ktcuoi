using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace TrinhMinhDat_ktcuoi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CalendarsController : ControllerBase
{
    private readonly AppDbContext _db;
    public CalendarsController(AppDbContext db) => _db = db;

    [HttpGet]
    public async Task<IActionResult> GetAll() => Ok(await _db.Calendars.Where(c => !c.IsHidden).ToListAsync());

    [HttpGet("all-admin")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAllAdmin() => Ok(await _db.Calendars.ToListAsync());

    [HttpPost]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<IActionResult> Create([FromBody] Calendar calendar)
    {
        _db.Calendars.Add(calendar);
        await _db.SaveChangesAsync();
        return Ok(calendar);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<IActionResult> Update(int id, [FromBody] Calendar updated)
    {
        var item = await _db.Calendars.FindAsync(id);
        if (item == null) return NotFound();
        item.Title = updated.Title;
        await _db.SaveChangesAsync();
        return Ok(item);
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var item = await _db.Calendars.FindAsync(id);
        if (item == null) return NotFound();
        _db.Calendars.Remove(item);
        await _db.SaveChangesAsync();
        return Ok();
    }

    [HttpPost("hide/{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Hide(int id)
    {
        var item = await _db.Calendars.FindAsync(id);
        if (item == null) return NotFound();
        item.IsHidden = true;
        await _db.SaveChangesAsync();
        return Ok(item);
    }
}
