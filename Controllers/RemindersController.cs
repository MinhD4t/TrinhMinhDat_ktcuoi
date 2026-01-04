using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace TrinhMinhDat_ktcuoi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class RemindersController : ControllerBase
{
    private readonly AppDbContext _db;
    public RemindersController(AppDbContext db) => _db = db;

    [HttpGet]
    public async Task<IActionResult> GetAll() => Ok(await _db.Reminders.Where(r => !r.IsHidden).Include(r => r.Event).ToListAsync());

    [HttpPost]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<IActionResult> Create([FromBody] Reminder reminder)
    {
        _db.Reminders.Add(reminder);
        await _db.SaveChangesAsync();
        return Ok(reminder);
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var item = await _db.Reminders.FindAsync(id);
        if (item == null) return NotFound();
        _db.Reminders.Remove(item);
        await _db.SaveChangesAsync();
        return Ok();
    }
}