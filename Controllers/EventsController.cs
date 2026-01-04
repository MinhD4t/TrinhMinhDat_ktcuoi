using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace TrinhMinhDat_ktcuoi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EventsController : ControllerBase
{
    private readonly AppDbContext _db;
    public EventsController(AppDbContext db) => _db = db;

    // VIEW: ALL ROLE
    [HttpGet]
    [Authorize(Roles = "Admin,Staff,User")]
    public async Task<IActionResult> GetAll()
        => Ok(await _db.Events
            .Where(e => !e.IsHidden)
            .Include(e => e.Calendar)
            .ToListAsync());

    // CREATE
    [HttpPost]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<IActionResult> Create(Event ev)
    {
        _db.Events.Add(ev);
        await _db.SaveChangesAsync();
        return Ok(ev);
    }

    // UPDATE
    [HttpPut("{id}")]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<IActionResult> Update(int id, Event updated)
    {
        var item = await _db.Events.FindAsync(id);
        if (item == null) return NotFound();

        item.Title = updated.Title;
        item.Start = updated.Start;
        item.End = updated.End;
        await _db.SaveChangesAsync();

        return Ok(item);
    }

    // DELETE
    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var item = await _db.Events.FindAsync(id);
        if (item == null) return NotFound();

        _db.Events.Remove(item);
        await _db.SaveChangesAsync();
        return Ok();
    }
}
